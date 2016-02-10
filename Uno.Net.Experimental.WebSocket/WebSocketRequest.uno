using Uno;
using Uno.Net.Http;

namespace Uno.Net.WebSocket
{
	public static class UnoRandom
	{
		static UnoRandom()
		{
            var seed = (int)(Uno.Diagnostics.Clock.GetTicks());
            debug_log "Seed " + seed;
            _Random = new Random(seed);
		}
		
		internal static readonly Random _Random;

        public static byte[] NextBytes(int length)
        {
        	var key = new byte[length];
            for(var i = 0; i < length; i++)
            {
            	key[i] = (byte)_Random.NextInt();
            }
            return key;
        }
	}

	public sealed class WebSocketRequest : HttpRequest
	{
		public WebSocketRequest(Uri uri) : base("GET", FixScheme(uri))
		{
			//var guid = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

			var key = Uno.Text.Base64.GetString(UnoRandom.NextBytes(16));

			Headers.Add("Connection", "keep-alive, Upgrade");
			Headers.Add("Upgrade", "websocket");

			//Headers.Add("Sec-WebSocket-Extensions", "permessage-deflate");
			Headers.Add("Sec-WebSocket-Version", "13");
			Headers.Add("Sec-WebSocket-Key", key);

			Headers.Add("Origin", Uri.Scheme + "://" + Uri.Host);
		}

		private static Uri FixScheme(Uri uri)
		{
			return new Uri(uri.AbsoluteUri.Replace("ws", "http"));
		}
	}
}