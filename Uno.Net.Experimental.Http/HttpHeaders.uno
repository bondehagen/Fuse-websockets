using Uno.Collections;

namespace Uno.Net.Http
{
	public class HttpHeaders 
	{
		readonly Dictionary<string, IList<string>> _headers;

		internal HttpHeaders()
		{
			_headers = new Dictionary<string, IList<string>>();
		}

		internal HttpHeaders(IEnumerable<string> headers) :this()
		{
			foreach (var headerLine in headers)
				ParseHeader(headerLine);
		}

		public string Location
		{
			get
			{
				IList<string> list;
				if (_headers.TryGetValue("location", out list))
					return list[0];

				return null;
			}
		}

		public string Connection
		{
			get
			{
				IList<string> list;
				if (_headers.TryGetValue("connection", out list))
					return list[0];

				return null;
			}
		}

		public string Upgrade
		{
			get
			{
				IList<string> list;
				if (_headers.TryGetValue("upgrade", out list))
					return list[0];

				return null;
			}
		}


		void ParseHeader(string headerLine)
		{
			// TODO: Validate according to http://www.bizcoder.com/everything-you-need-to-know-about-http-header-syntax-but-were-afraid-to-ask
			var colon = headerLine.IndexOf(':');
			var name = headerLine.Substring(0, colon).Trim().ToLower();

			// https://tools.ietf.org/html/rfc7230#section-3.2.4
            var strings = headerLine.Substring(colon + 1, headerLine.Length - (colon + 1)).Trim().Split(';');
            var values = new List<string>();
            foreach (var s in strings)
            {
                values.Add(s.Trim());
            }

			if (_headers.ContainsKey(name))
			{
				foreach (var value in values)
					_headers[name].Add(value);
			}
			else
				_headers.Add(name, values);
		}
	}
}