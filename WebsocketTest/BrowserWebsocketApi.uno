using Uno;
using Uno.Threading;
using Uno.Net.WebSocket;

namespace Uno.Net
{
	public class BrowserWebsocketApi : IDisposable
	{
		public const ushort CONNECTING = 0;
		public const ushort OPEN = 1;
		public const ushort CLOSING = 2;
		public const ushort CLOSED = 3;

		public readonly ulong bufferedAmount;
		public readonly string extensions;
		public readonly string protocol;
		public ushort readyState;

		public string url;

		public string binaryType;

		public Action onclose;
		public Action<string> onerror;
		public Action<string> onmessage;
		public Action onopen;

		readonly WebSocketClient _webSocket;

		public BrowserWebsocketApi(Uno.Net.Http.Uri url)
		{
			this.readyState = CONNECTING;
            this.url = url.ToString();
			_webSocket = new WebSocketClient();
			_webSocket.Connect(url).Then(OnConnected, OnConnectingFailed);
		}

		public void close(ushort code = 0, string reason = "")
		{
			if(readyState >= CLOSING) return;

			this.readyState = CLOSING;
			_webSocket.Close("", reason);
		}

		public void send(string data)
		{
			_webSocket.Send(data);
		}

		void OnConnectingFailed(Exception e)
		{
			debug_log "ConnectingFailed " + e;
			readyState = CLOSED;
			if (_webSocket != null)
				_webSocket.Dispose();

			onerror(e.Message);
		}
		
		void OnReceiveFailed(Exception e)
		{
			debug_log "e " + e;
			readyState = CLOSED;
			if (_webSocket != null)
				_webSocket.Dispose();

			onerror("Could not read from stream");
		}

		void OnConnected(bool isValid)
		{
			debug_log "Validate response" + isValid;
			if(isValid) {
				readyState = OPEN;
				Promise<bool>.Run(ReadLoop);
				if(onopen != null)
					onopen();

				return;
			}
			readyState = CLOSED;
			if (_webSocket != null)
				_webSocket.Dispose();

			onerror("Invalid response");
		}

		public void Dispose()
        {
            if (_webSocket != null)
                _webSocket.Dispose();
        }

		bool ReadLoop()
		{
			var _isClosed = false;
			while (!_isClosed && _webSocket != null && readyState < CLOSING)
			{
				try
				{
					debug_log (".");
					var result = _webSocket.ReceiveSync();
					_isClosed = result.IsClosed;
					if(!_isClosed)
						onmessage(result.Message); 
				}
				catch (Exception e)
				{
					_isClosed = true;
                    onerror(e.Message);
					debug_log(e);
				}
			}
			debug_log "Closed";
            readyState = CLOSED;
            if (_webSocket != null)
                _webSocket.Dispose();

            if (onclose != null)
                onclose();

            return true;
		}
	}
}