using Uno;
using Uno.Collections;
using Uno.IO;
using Uno.Net;
using Uno.Net.Sockets;
using Uno.Text;

namespace Uno.Net.Http
{
    public class HttpMessage
    {
		public static HttpResponse Execute(HttpRequest request, bool allowAutoRedirect, int maxRedirects)
		{
			var redirectCount = 0;
			while (redirectCount++ < maxRedirects)
			{
				try
				{
					ValidateUri(request.Uri);

					IPAddress address;
					if(!DnsCache.TryGetAddress(request.Uri.Host, out address))
						throw new Exception("Could not resolve host address");
					
					NetworkStream stream;
					if (!TryConnect(request, new IPEndPoint(address, request.Uri.Port), out stream))
						throw new Exception("Could not connect to host");

					Send(stream, request);

					/* NOTE: This make the client hang at a later call to DataAvailable!
					var timeout = 10;
					var startTime = Uno.Diagnostics.Clock.GetSeconds();
					var elapsed = startTime;
					while (!stream.DataAvailable && (elapsed - startTime) <= timeout)
					{
						Uno.Threading.Thread.Sleep(10);
						elapsed = Uno.Diagnostics.Clock.GetSeconds();
					}
					if((elapsed - startTime) >= timeout)
						throw new Exception("Timeout when receiving message from server");*/

					var httpResponse = Read(stream);

					if (allowAutoRedirect && (httpResponse.StatusLine.StatusCode >= 300 && httpResponse.StatusLine.StatusCode < 400))
					{
						var location = httpResponse.Headers.Location;
						if (location == null) return httpResponse;

						// Redirect
						stream.Close();
						request = request.Clone();
						request.Uri = new Uri(location); // TODO: DNS caching?

						continue;
					}
					return httpResponse;
				}
				catch (Exception e)
				{
					debug_log(e);
					throw e;
				}
				break;
			}
			return null;
		}

		static bool TryConnect(HttpRequest request, IPEndPoint endpoint, out NetworkStream stream)
		{
			stream = null;
			try
			{
				var socket = Socket.Create(endpoint.AddressFamily, SocketType.Stream, ProtocolType.Tcp);
				socket.Connect(endpoint);
				// TODO: validate connection http://stackoverflow.com/questions/2661764/how-to-check-if-a-socket-is-connected-disconnected-in-c
				stream = new NetworkStream(socket);

				if (request.IsSecure)
				{
					if (SslThing.SetupSecureStream(request, stream, socket, out stream)) return true;
				}
				if(stream == null) return false;
			}
			catch(Exception e)
			{
				return false;
			}
			return true;
		}

		static bool ValidateUri(Uri uri)
		{
			if (string.IsNullOrEmpty(uri.Host))
				throw new Exception("Invalid hostname.");

			if (string.IsNullOrEmpty(uri.Scheme) && !(uri.Scheme.ToLower().Equals("http") || uri.Scheme.ToLower().Equals("https")))
				throw new Exception("Invalid scheme.");

			return true;
		}

	    static HttpResponse Read(NetworkStream stream)
		{
			debug_log("--------- Response ----------");
			var sb = new StringBuilder();
			var reader = new StreamReader(stream);//, Encoding.ASCII);

			//Start-line (status-line) https://tools.ietf.org/html/rfc7230#section-3.1.2
			var statusLine = reader.ReadLine();
			if(statusLine == null)
				throw new Exception("Could not read response stream");
			
			sb.AppendLine(statusLine);
			/* TODO A recipient that receives whitespace between the
			start-line and the first header field MUST either reject the message
			as invalid or consume each whitespace-preceded line without further
			processing of it (i.e., ignore the entire line, along with any
			subsequent lines preceded by whitespace, until a properly formed
			header field is received or the header section is terminated).*/

			// Headers
			var headers = new List<string>();
			var headerLine = reader.ReadLine();
			while (!string.IsNullOrEmpty(headerLine))
			{
				headers.Add(headerLine);
				sb.AppendLine(headerLine);
				headerLine = reader.ReadLine();
			}

			debug_log(sb.ToString());
			debug_log("-----------------------------");

			return new HttpResponse(new HttpStatusLine(statusLine), new HttpHeaders(headers), new HttpBody(stream));
		}

	    static void Send(NetworkStream stream, HttpRequest request)
		{
			var requestStringBuilder = new StringBuilder();

			// Start-line (request-line)
			var requestTarget = GetRequestTarget(request);
			var requestLine = request.Method.Trim(' ').ToUpper() + " " + requestTarget.Trim(' ') + " " + request.Version.Trim(' ');
			requestStringBuilder.AppendLine(requestLine);

			// Headers https://tools.ietf.org/html/rfc7230#section-3.1.2
			/* A sender MUST NOT generate multiple header fields with the same field 
			name in a message unless either the entire field value for that 
			header field is defined as a comma-separated list [i.e., #(values)] 
			or the header field is a well-known exception (as noted below).*/
			foreach (var h in request.Headers)
				requestStringBuilder.AppendLine(h.Key + ": " + h.Value);

			requestStringBuilder.AppendLine(""); // Signal end of header section

			var writer = new StreamWriter(stream);//, Encoding.ASCII);
			var requestString = requestStringBuilder.ToString();

			debug_log("--------- Request ----------");
			debug_log(requestString);
			debug_log("-----------------------------");
			writer.Write(requestString);

			// Optional message body https://tools.ietf.org/html/rfc7230#section-3.3

			writer.Flush();
		}

		// https://tools.ietf.org/html/rfc7230#section-3.1.1
	    static string GetRequestTarget(HttpRequest request)
		{
			if (request.Method == "CONNECT")
			{
				return request.Uri.Authority;
			}
			if (request.Method == "OPTIONS")
			{
				return "*"; // NOTE: https://tools.ietf.org/html/rfc7230#section-5.3.4
			}
			bool proxy = false;
			if (proxy)
			{
				return request.Uri.AbsoluteUri;
			}
			return request.Uri.PathAndQuery;
		}
    }

    class DnsCache
    {
    	public static bool TryGetAddress(string hostNameOrAddress, out IPAddress address)
    	{
    		address = null;
    		try
    		{
	    		var addresses = Dns.GetHostAddresses(hostNameOrAddress);
	    		// TODO: cache result
				if(addresses == null || addresses.Length == 0)
					return false;
				
				address = addresses[0];
				if(address == null)
					return false;
			}
			catch (Exception e)
			{
				return false;
			}
			return true;
    	}
    }
}
 