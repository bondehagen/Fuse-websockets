using Uno.Net.Http;

namespace Uno.Net.WebSocket
{
	public sealed class WebSocketResponse : HttpResponse
	{
		public WebSocketResponse(HttpResponse result) : base(result.StatusLine, result.Headers, result.Body)
		{
			if (StatusLine.StatusCode == 101 && Headers.Upgrade != null && Headers.Upgrade.ToLower() == "websocket" &&
               Headers.Connection != null && Headers.Connection.ToLower() == "upgrade")
			{
				IsValidWebSocket = true;
			}
		}

        public WebSocketStream WebSocketsStream { get { return new WebSocketStream(Body._stream); } }

		public bool IsValidWebSocket { get; private set; }
		public string SubProtocol { get; private set; }
	}
}