# Immutable Vector

Based on *RRB Vector: A Practical General Purpose Immutable Sequence, ICFP'15*.

It supports normal vector operations ($m$ is the branching factor and $n$ is the number of elements):
- Indexing in $O(\log_2{m} \cdot \log_m{n})$
- Updating in $O(m \cdot \log_m{n})$
- Removal in $O(m^2 \cdot \log_m{n})$
- Appending in $O(m \cdot \log_m{n})$
- Splitting in $O(m \cdot \log_m{n})$
- Concatenation in $O(m^2 \cdot \log_m{n})$