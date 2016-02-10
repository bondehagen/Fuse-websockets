using Uno;
using Uno.IO;

namespace Uno.Net.WebSocket
{
    public enum Opcodes : byte
    {
        ContinuationFrame = 0x0,
        TextFrame = 0x1,
        BinaryFrame = 0x2,
        Close = 0x8,
        Ping = 0x9,
        Pong = 0xA
    }
    class WebSocketFrame
    {
        private bool _rsv1;
        private bool _rsv2;
        private bool _rsv3;
        int _payloadLength;

        private byte[] _payLoad;

        public bool Fin { get; set; }

        public bool Rsv1
        {
            get { return _rsv1; }
        }

        public bool Rsv2
        {
            get { return _rsv2; }
        }

        public bool Rsv3
        {
            get { return _rsv3; }
        }

        public Opcodes Opcode { get; set;  }

        public bool Masked { get; private set; }

		public byte[] MaskingKey { get; set; }

        public int PayloadLength
        {
            get { return _payloadLength; }
        }

		public ulong ExtendedPayloadLength { get; set; }
        public byte[] PayLoad { get { return _payLoad; } }

        private WebSocketFrame(bool fin, bool rsv1, bool rsv2, bool rsv3, Opcodes opcode, bool masked, int payloadLength)
        {
            Fin = fin;
            _rsv1 = rsv1;
            _rsv2 = rsv2;
            _rsv3 = rsv3;
            Opcode = opcode;
            Masked = masked;
            _payloadLength = payloadLength;
        }

        public WebSocketFrame(bool fin, Opcodes opcode, bool masked, byte[] payLoad)
            : this(fin, false, false, false, opcode, masked, payLoad.Length)
        {
            MaskingKey = (masked) ? UnoRandom.NextBytes(4) : new byte[0];
            _payLoad = payLoad;
        }

        private WebSocketFrame(Stream stream)
        {
            ReadInternal(stream);
        }

        public byte[] ToArray()
        {
            using (var stream = new MemoryStream())
            {
                Write(stream);
                var res = new byte[(int)stream.Length];
                Array.Copy(stream.GetBuffer(), res, (int)res.Length); // truncate buffer
                return res;
            }
            return new byte[0];
        }

        private byte[] GetHeader()
        {
            int firstByte = 0x00;
            firstByte |= Fin ? 0x80 : 0x00;
            firstByte |= _rsv1 ? 0x40 : 0x00;
            firstByte |= _rsv2 ? 0x20 : 0x00;
            firstByte |= _rsv3 ? 0x10 : 0x00;
            firstByte |= (byte) Opcode & 0x0F;

            int secondByte = _payloadLength < 126 ? _payloadLength : 126; // TODO: put the rest in extendlength
            if (Masked)
                secondByte |= 0x80;

            return new []
            {
                (byte)firstByte,
                (byte)secondByte
            };
        }

        public static WebSocketFrame Read(Stream stream)
        {
            return new WebSocketFrame(stream);
        }

        public static WebSocketFrame Write(Stream stream, Opcodes opcode, byte[] applicationData)
        {
            var webSocketFrame = new WebSocketFrame(true, opcode, true, applicationData);
            webSocketFrame.Write(stream);
            return webSocketFrame;
        }

        public void Write(Stream stream)
        {
            var br = new BinaryWriter(stream);
            br.Write(GetHeader());

            // extended length
            if (PayloadLength == 126)
                br.Write((ushort) PayloadLength);
            else if (PayloadLength > 126)
                br.Write((ulong) PayloadLength);

            if (Masked)
            {
                var payLoad = new byte[PayloadLength];
                Array.Copy(_payLoad, payLoad, PayloadLength);
                for (var i = 0; i < PayloadLength; i++)
                    payLoad[i] = (byte)(payLoad[i] ^ MaskingKey[i % 4]);

                br.Write(MaskingKey);
                br.Write(payLoad);
            }
            else
                br.Write(_payLoad);

            stream.Flush();
        }

        void ReadInternal(Stream stream)
        {
            var binaryReader = new BinaryReader(stream);
            var header = binaryReader.ReadBytes(2);
            Fin = (header[0] & 0x80) != 0;
            _rsv1 = (header[0] & 0x40) != 0;
            _rsv2 = (header[0] & 0x20) != 0;
            _rsv3 = (header[0] & 0x10) != 0;

            Opcode = (Opcodes) (header[0] & 0x0F);
            Masked = (header[1] & 0x80) == 0x80;
            _payloadLength = header[1] & 0x7F;

            // extended payload length
            if (_payloadLength == 0x7F)
                ExtendedPayloadLength = binaryReader.ReadULong();
            else if (PayloadLength == 0x7E)
                ExtendedPayloadLength = binaryReader.ReadUShort();

            if (Masked)
                MaskingKey = binaryReader.ReadBytes(4);

            // Payload data (TODO: Extension+Application data) https://tools.ietf.org/html/rfc6455#section-5.2
            _payLoad = ExtendedPayloadLength > 0
                ? new byte[(int)ExtendedPayloadLength]
                : new byte[PayloadLength];

            stream.Read(_payLoad, 0, _payLoad.Length);

            if (Masked)
            {
                for (var i = 0; i < PayloadLength; i++)
                    _payLoad[i] = (byte)(_payLoad[i] ^ MaskingKey[i % 4]);
            }
        }
    }

    public enum CloseStatusCode : ushort
    {
        Normal = 1000,
        Away = 1001,
        ProtocolError = 1002,
        UnsupportedData = 1003,
        Undefined = 1004,
        NoStatus = 1005,
        Abnormal = 1006,
        InvalidData = 1007,
        PolicyViolation = 1008,
        TooBig = 1009,
        MandatoryExtension = 1010,
        ServerError = 1011,
        TlsHandshakeFailure = 1015
    }
}