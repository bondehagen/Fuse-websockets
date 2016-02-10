using Uno;
using Uno.Threading;

namespace Uno.Net.Http
{
    public class HttpClient
    {
		public static Future<HttpResponse> Send(HttpRequest request)
        {
            return Promise<HttpResponse>.Run(new SendClosure(request).Run);
        }

        class SendClosure
        {
        	const int MaxRedirects = 5;
			const bool AllowAutoRedirect = true;
        	HttpRequest _request;

        	public SendClosure(HttpRequest request)
        	{
        		_request = request;
        	}
        	public HttpResponse Run()
        	{
        		return HttpMessage.Execute(_request, AllowAutoRedirect, MaxRedirects);
        	}
        }
    }
}