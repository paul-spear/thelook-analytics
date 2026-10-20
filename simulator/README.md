# Change simulator

Replays theLook public data into `raw_thelook` one simulated day per run, mutating
rows so SCD2 and incremental logic are exercised. Built in Phase 1 of the guide.

Planned interface:

```bash
python simulator/replay.py --days 1 [--late-rate 0.02] [--dup-rate 0.01] [--delete-rate 0.001]
```
