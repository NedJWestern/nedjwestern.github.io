---
layout: default
title: View Plots via SSH
---

You have only an SSH connection to a remote Linux server. During exploratory data analysis, you need a convenient, mouse-free way to update and view plots.

Pros
- Update your image mouse-free.
- Serve dynamic html images or static png images.
- Interactive matplotlib images.

In your SSH connection, forward a port like so
```bash
ssh -L 8000:localhost:8000 your_user_name@your_server
```

On the remote server, `cd` to your plots directory and create a [HTTP server](https://docs.python.org/3/library/http.server.html) to serve your directory
```bash
python -m http.server
```

Or, to skip the `cd` step, point the server directly at your plots directory (adjust your saved plot paths to match)
```bash
python -m http.server --directory tmp/ 8000
```

Use `mpld3` to save `matplotlib` images as interactive html files.
```python
df.plot()
mpld3.save_html(plt.gcf(), "plot.html")
plt.close()
```

View your images locally in a browser at
```
localhost:8000
```
