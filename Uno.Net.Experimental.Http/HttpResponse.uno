namespace Uno.Net.Http
{
    public class HttpResponse
    {
		public HttpStatusLine StatusLine { get; private set; }

	    public HttpHeaders Headers { get; private set; }

		public HttpBody Body { get; private set; }

	    internal HttpResponse(HttpStatusLine statusLine, HttpHeaders headers, HttpBody body)
	    {
			StatusLine = statusLine;
			Headers = headers;
			Body = body;
	    }

	    public HttpResponse Clone()
	    {
		    return new HttpResponse(StatusLine, Headers, Body);
	    }

	    public override string ToString()
	    {
		    const string newLine = "\n";
			return StatusLine + newLine + Headers + newLine + newLine + Body;
	    }
    }
}