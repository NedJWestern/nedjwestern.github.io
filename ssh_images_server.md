# SSH images server

In your SSH connection, forward a port like so
```bash
ssh -L 8988:localhost:8988 your_user_name@your_server
```

On the remote server, create a HTTP server to server your
```bash
python -m http.server 8988
```

Pros
- Serve dynamic html images or static png images
- Mouse free updating of your image

```python
df.plot()
mpld3.save_html(plt.gcf(), "tmp/plots/plot.html")
plt.close()
```