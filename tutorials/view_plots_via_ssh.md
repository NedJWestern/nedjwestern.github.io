---
layout: default
title: View Plots via SSH
---

You have only an SSH connection to a remote Linux server. During exploratory data analysis, you need a convenient, mouse-free way to update and view plots.

Pros
- Update your image mouse-free.
- Serve dynamic html images or static png images.
- Interactive matplotlib images.


# Setup

In your SSH connection, forward a port like so
```bash
ssh -L 8000:localhost:8000 your_user_name@your_server
```

On the remote server, `cd` to your plots directory and create a [HTTP server](https://docs.python.org/3/library/http.server.html) to serve your directory
```bash
python -m http.server --bind 127.0.0.1 8000
```

`--bind 127.0.0.1` matters: without it, the server listens on every network interface, so anyone who can reach the server can browse your plots (and anything else in that directory). With it, only your SSH tunnel can.

Or, to skip the `cd` step, point the server directly at your plots directory (adjust your saved plot paths to match)
```bash
python -m http.server --bind 127.0.0.1 --directory tmp/ 8000
```

# Interactive Plots

Install `mpld3`
```bash
pip install mpld3
```

Use `mpld3` to save `matplotlib` images as interactive html files.
```python
import matplotlib.pyplot as plt
import mpld3

df.plot()
mpld3.save_html(plt.gcf(), "plot.html")
plt.close()
```

View your images locally in a browser at
```
localhost:8000
```
