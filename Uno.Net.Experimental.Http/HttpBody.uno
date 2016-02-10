using Uno.Net.Sockets;

namespace Uno.Net.Http
{
	public class HttpBody
	{
		protected internal readonly NetworkStream _stream;

		// Message body https://tools.ietf.org/html/rfc7230#section-3.3
		public HttpBody(NetworkStream stream)
		{
			_stream = stream;
		}
	}
}