using Uno;
using Uno.Collections;

namespace Uno.Net.Http
{
    public class HttpRequest
    {
	    public Uri Uri { get; set; }

	    public Dictionary<string, string> Headers { get; private set; }

	    public bool IsSecure
        {
            get { return Uri.Scheme.ToLower().Equals("https"); }
        }

        public string Method { get; private set; }
	    public string Version { get { return "HTTP/1.1"; } }

        public HttpRequest(string method, Uri uri)
        {
            Method = method;
            Uri = uri;
            Headers = new Dictionary<string, string>();

            var port = uri.Port == 80 || uri.Port == 443 ? "" : ":" + uri.Port;
            var host = uri.Host + port;
            Headers.Add("Host", host);
            Headers.Add("Cache-Control", "no-cache");
            Headers.Add("Pragma", "no-cache");
			Headers.Add("User-Agent", "Fuseclient/0.1");
        }

	    internal virtual HttpRequest Clone()
	    {
		    return new HttpRequest(Method, Uri) { Headers = Headers };
	    }
    }
}