# Glossary

Business terms mapped to where they live in the project. The semantic layer is the
source of truth for metric definitions; this page points to it.

| Term | Meaning | Metric / column |
| --- | --- | --- |
| Revenue (also: sales, GMV) | Sum of sale price of items in non-cancelled orders, USD | `revenue` (to define in Phase 7) |
| AOV | Average order value: revenue / orders | `average_order_value` |
| As was / as is | Attributes at the time of the event vs today | SCD2 join vs `is_current` |
