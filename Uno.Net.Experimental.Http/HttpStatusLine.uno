using Uno;

namespace Uno.Net.Http
{
	public class HttpStatusLine
	{
		readonly string _reasonPhrase;
		readonly string _raw;

		public string ReasonPhrase
		{
			get { return HttpStatusReasonPhrase.GetFromStatusCode(StatusCode); }
		}

		public int StatusCode { get; private set; }

		public string Version { get; private set; }

		internal HttpStatusLine(string line)
		{
			if (line == null || !line.StartsWith("HTTP/"))
				throw new Exception("Invalid status line");

			_raw = line;
			var statusLine = line.Split(' ');
			Version = statusLine[0];
			StatusCode = int.Parse(statusLine[1]); // 3-digit
			if (statusLine.Length > 1)
			{
				// TODO: Should only set if not exists in list: HttpStatusReasonPhrase;
				for (var i = 2; i < statusLine.Length; i++)
					_reasonPhrase += statusLine[i];
			}
		}

		public override string ToString()
		{
			return _raw;
		}
	}
}