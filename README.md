# progress-d

A simple progress bar library implemented in D lang.

# Example

```d
void main(string[] args) {
  size_t iteration = 100;
  Progress p = new Progress(iteration);
  p.title = "Downloading";

  for(int i = 0; i < iteration; i++) {
    p.next();
    Thread.sleep(dur!("msecs")(80));
  }
  writeln();
}
```

```
Downloading  41% |ooooooooooooooooo                       | ETA 00:00:04
```
