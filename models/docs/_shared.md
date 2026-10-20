{% docs _loaded_at %}
UTC timestamp when the row landed in `raw_thelook`. Set by the change simulator, not
the source system. Use it for incremental filters, never for business logic.
{% enddocs %}

{% docs scd2_valid_from %}
UTC timestamp from which this version of the record was true (inclusive).
For point-in-time joins use `valid_from <= event_at and event_at < valid_to`.
{% enddocs %}

{% docs scd2_valid_to %}
UTC timestamp at which this version stopped being true (exclusive).
`9999-12-31 00:00:00` for the current version, never null.
{% enddocs %}

{% docs scd2_is_current %}
True for exactly one row per natural key: the version that is true now.
Hard-deleted records have no current row.
{% enddocs %}
