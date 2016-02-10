using Uno;
using Uno.Threading;
using Uno.Net.Http;

namespace Uno.Net.WebSocket
{
    public sealed class WebSocketClient : IDisposable
    {
        WebSocketStream _stream;
        Promise<bool> _onconnected;

        public Future<bool> Connect(Uri uri)
        {
        	_onconnected = new Promise<bool>();
        	HttpClient.Send(new WebSocketRequest(uri)).Then(Create).Catch(Err);
	        return _onconnected;
        }

	    void Create(HttpResponse r)
	    {
			_onconnected.Resolve(Validate(new WebSocketResponse(r)));
	    }
	    
	    void Err(Exception e)
	    {
	    	_onconnected.Reject(e);
	    }

	    bool Validate(WebSocketResponse response)
	    {
		    if (!response.IsValidWebSocket) return false;

			_stream = response.WebSocketsStream;
            if(_stream == null)
                return false;

			State = WebSocketState.Open;
			SubProtocol = response.SubProtocol;

			// TOOD: start ping loop
			//task.Then(PingLoop);

		    return true;
	    }
	    
	    void PingLoop(WebSocketResponse obj)
	    {
			_stream.SendFrame(Opcodes.Ping, "ping");
	    }

	    public Future Send(string message)
        {
			return Promise<bool>.Run(new SendMessageClosure(_stream, message).Send);
        }
        
        public WebSocketReceiveResult ReceiveSync()
        {
			string message = "";
			var readMessage = (_stream != null) ? _stream.ReadMessage(out message) : true;
			return new WebSocketReceiveResult(readMessage, message);
        } 
        
        public Future<WebSocketReceiveResult> Receive()
        {
        	return Promise<WebSocketReceiveResult>.Run(ReceiveSync);
        }

	    public Future Close(string closeStatus, string statusDescription)
	    {
            if(_stream == null)
            {
                // TODO: Abort connection attempt if ongoing.
                _onconnected.Reject(new Exception("Connection attempt aborted by user"));
                return new Promise<bool>(true);
            }
            //TODO: shutdown if not close handshake completes
			return Promise<bool>.Run(new SendCloseClosure(_stream, closeStatus, statusDescription).Send);
	    }
        
        //public ClientWebSocketOptions Options { get; }
        //public WebSocketCloseStatus? CloseStatus { get; }
        //public string CloseStatusDescription { get; }
        public string SubProtocol { get; set; }
        public WebSocketState State { get; private set; }

        public void Dispose()
        {
            _stream.Dispose();
        }

        class SendMessageClosure
        {
            readonly string _message;
            readonly WebSocketStream _stream;

            public SendMessageClosure(WebSocketStream stream, string message)
            {
                _stream = stream;
                _message = message;
            }

            public bool Send()
            {
                _stream.SendFrame(Opcodes.TextFrame, _message);
                return true;
            }
        }

        class SendCloseClosure
        {
            readonly WebSocketStream _stream;
            readonly string _closeStatus;
            readonly string _statusDescription;

            public SendCloseClosure(WebSocketStream stream, string closeStatus, string statusDescription)
            {
                _stream = stream;
                _closeStatus = closeStatus;
                _statusDescription = statusDescription;
            }

            public bool Send()
            {
                // TOOD: description and status
                _stream.SendFrame(Opcodes.Close, new byte[0]);
                return true;
            }
        }

    }

	public enum WebSocketState
	{
		Open
	}

	public sealed class WebSocketReceiveResult
	{
		readonly bool _isClosed;

		public WebSocketReceiveResult(bool isClosed, string message)
		{
			_isClosed = isClosed;
			Message = message;
		}

		public bool IsClosed
		{
			get { return _isClosed; }
		}

		public string Message;
	}
}