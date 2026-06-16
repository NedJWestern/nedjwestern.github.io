# SSH images server

You have only a SSH connection to a remote Linux server. During exploratory data analysis, you need a convenient, mouse-free way to update and view plots.

Pros
- Update your image mouse-free.
- Serve dynamic html images or static png images.
- Interactive matplotlib images.

In your SSH connection, forward a port like so
```bash
ssh -L 8988:localhost:8988 your_user_name@your_server
```

On the remote server, create a [HTTP server](https://docs.python.org/3/library/http.server.html) to server your directory
```bash
python -m http.server 8988
```

Or set a particular directory with
```bash
--directory tmp/
```

Use `mpld3` to save `matplotlib` images as interactive html files.
```python
df.plot()
mpld3.save_html(plt.gcf(), "tmp/plots/plot.html")
plt.close()
```

View your images locally in a browser at

```
localhost:8988
```
