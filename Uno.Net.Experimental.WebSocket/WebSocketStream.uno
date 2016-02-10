using Uno;
using Uno.IO;
using Uno.Net.Sockets;

namespace Uno.Net.WebSocket
{
    public class WebSocketStream : Stream
    {
        private NetworkStream _innerStream;

        internal WebSocketStream(NetworkStream stream)
        {
            _innerStream = stream;
        }

        protected NetworkStream InnerStream
        {
            get { return _innerStream; }
        }

        public override void Flush()
        {
            _innerStream.Flush();
        }

        public override long Seek(long offset, SeekOrigin origin)
        {
            return _innerStream.Seek(offset, origin);
        }

        public override void SetLength(long value)
        {
            _innerStream.SetLength(value);
        }

        public override int Read(byte[] buffer, int offset, int count)
        {
            return _innerStream.Read(buffer, offset, count);
        }

        public override void Write(byte[] buffer, int offset, int count)
        {
            _innerStream.Write(buffer, offset, count);
        }

        public override bool CanRead
        {
            get { return _innerStream.CanRead; }
        }

        public override bool CanSeek
        {
            get { return _innerStream.CanSeek; }
        }

        public override bool CanWrite
        {
            get { return _innerStream.CanWrite; }
        }

        public override long Length
        {
            get { return _innerStream.Length; }
        }

        public override long Position { get; set; }

        public void SendFrame(Opcodes opcode, string applicationData)
        {
            var bytes = Uno.Text.Utf8.GetBytes(applicationData);
            SendFrame(opcode, bytes);
        }

        public void SendFrame(Opcodes opcode, byte[] applicationData)
        {
            WebSocketFrame.Write(_innerStream, opcode, applicationData);
        }

        public bool ReadMessage(out string message)
        {
            message = null;
            if (_innerStream == null)
            {
                debug_log "Inner stream was null";
                return true;
            }
            // TODO: set up ping loop so this can have some timeout functionality
            while (!_innerStream.DataAvailable)
            {
                Threading.Thread.Sleep(10);
            }
            
            var webSocketFrame = WebSocketFrame.Read(_innerStream);
            if (!webSocketFrame.Fin) // Is not final frame?
                debug_log("Not final frame, opcode " + webSocketFrame.Opcode);

            switch (webSocketFrame.Opcode)
            {
                case Opcodes.ContinuationFrame:
                    debug_log("Received ContinuationFrame " + webSocketFrame.PayLoad.Length);
                    break;
                case Opcodes.TextFrame:
                    message = Uno.Text.Utf8.GetString(webSocketFrame.PayLoad);
                    debug_log(message);
                    break;
                case Opcodes.BinaryFrame:
                    debug_log("Received Binary");
                    break;
                case Opcodes.Close:
                    var closeCode = (CloseStatusCode)((webSocketFrame.PayLoad[0] << 8) + webSocketFrame.PayLoad[1]);
                    debug_log("Received close: " + closeCode);
                    _innerStream.Close();
                    return true;
                    break;
                case Opcodes.Ping:
                    debug_log("Received Ping");
                    SendFrame(Opcodes.Pong, webSocketFrame.PayLoad);
                    break;
                case Opcodes.Pong:
                    // Ignore
                    debug_log("Received Pong");
                    break;
                default:
                    debug_log("Unknown opcode " + webSocketFrame.Opcode);
                    break;
            }
            return false;
        }

        public override void Dispose(bool disposing)
        {
            try
            {
                if (disposing)
                    _innerStream.Close();
            }
            finally
            {
                base.Dispose(disposing);
            }
        }
    }
}
