

# when using longest

```mbt check
lexmatch s using longest {
  ("re1" ("re2" as re2), next)  => ...
  ...
}
```

This adopts the Posix standard, the left side 
has an implicit "$"  at the beginning
(No shortest like ocamllex)

# default

```mbt check
lexmatch s {
    (_,"re1" ("re2" as r) ,_) => ...
    "re3" => ... // implicit $ at the beginning and ^ at end
    (_, "\.(.*)") => ... // implicit  ^ at end
    ...
}
```
Top down, matched one by one using re2 style submatch semantics

```mbt check
if s lexmatch? (_,"re1" ("re2" as r) ,_) {
    ...
}
```



