"""Replay the frozen theLook copy into raw_thelook, one simulated day per run.

Usage:
    python simulator/replay.py init --start 2026-06-01   # create tables, load history
    python simulator/replay.py run --days 3              # land the next 3 days
    python simulator/replay.py status                    # show the simulated clock

The project comes from --project or the GCP_PROJECT environment variable.
"""

import argparse
import datetime as dt
import os
import sys
from pathlib import Path
from string import Template

from google.cloud import bigquery

SQL_DIR = Path(__file__).parent / "sql"
SOURCE_DATASET = "thelook_source"  # frozen copy; the simulator never reads the public data
RAW_DATASET = "raw_thelook"
MAX_BYTES_BILLED = 2 * 10**9  # per script; a day touches well under 1 GB


def render(path: Path, project: str) -> str:
    return Template(path.read_text()).substitute(
        project=project, source=SOURCE_DATASET, raw=RAW_DATASET
    )


def run_script(client: bigquery.Client, sql: str, params: list) -> None:
    config = bigquery.QueryJobConfig(
        query_parameters=params, maximum_bytes_billed=MAX_BYTES_BILLED
    )
    client.query(sql, job_config=config).result()


def run_folder(client: bigquery.Client, project: str, folder: str, params: list) -> None:
    for path in sorted((SQL_DIR / folder).glob("*.sql")):
        print(f"  {folder}/{path.name}")
        run_script(client, render(path, project), params)


def get_state(client: bigquery.Client, project: str) -> dt.date | None:
    rows = list(client.query(
        f"select max(sim_date) as sim_date from `{project}.{RAW_DATASET}._sim_state`"
    ).result())
    return rows[0].sim_date if rows else None


def set_state(client: bigquery.Client, project: str, sim_date: dt.date) -> None:
    run_script(
        client,
        f"""
        delete from `{project}.{RAW_DATASET}._sim_state` where true;
        insert into `{project}.{RAW_DATASET}._sim_state` values (@sim_date, current_timestamp());
        """,
        [bigquery.ScalarQueryParameter("sim_date", "DATE", sim_date)],
    )


def horizon(client: bigquery.Client, project: str) -> dt.date:
    """Last day the frozen copy covers: the day it was copied."""
    table = client.get_table(f"{project}.{SOURCE_DATASET}.orders")
    return table.created.date() - dt.timedelta(days=1)


def cmd_init(client: bigquery.Client, project: str, start: dt.date) -> None:
    print(f"Initialising {project}.{RAW_DATASET}, history before {start}")
    run_folder(client, project, "init",
               [bigquery.ScalarQueryParameter("start_date", "DATE", start)])
    set_state(client, project, start - dt.timedelta(days=1))
    print(f"Done. Next run lands {start}.")


def cmd_run(client: bigquery.Client, project: str, days: int) -> None:
    last = get_state(client, project)
    if last is None:
        sys.exit("No simulator state found. Run `init` first.")
    limit = horizon(client, project)
    for _ in range(days):
        sim_date = last + dt.timedelta(days=1)
        if sim_date > limit:
            print(f"Reached the end of the frozen data ({limit}). Stopping.")
            break
        print(f"Landing {sim_date}")
        run_folder(client, project, "daily",
                   [bigquery.ScalarQueryParameter("sim_date", "DATE", sim_date)])
        set_state(client, project, sim_date)  # only after every file succeeded
        last = sim_date


def cmd_status(client: bigquery.Client, project: str) -> None:
    print(f"Last landed day: {get_state(client, project)}")
    print(f"Data runs out:   {horizon(client, project)}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--project", default=os.environ.get("GCP_PROJECT"))
    sub = parser.add_subparsers(dest="command", required=True)
    init = sub.add_parser("init", help="create tables and load history")
    init.add_argument("--start", type=dt.date.fromisoformat, required=True)
    run = sub.add_parser("run", help="land the next N simulated days")
    run.add_argument("--days", type=int, default=1)
    sub.add_parser("status", help="show the simulated clock")
    args = parser.parse_args()

    if not args.project:
        sys.exit("Set --project or the GCP_PROJECT environment variable.")
    client = bigquery.Client(project=args.project)

    if args.command == "init":
        cmd_init(client, args.project, args.start)
    elif args.command == "run":
        cmd_run(client, args.project, args.days)
    else:
        cmd_status(client, args.project)


if __name__ == "__main__":
    main()
