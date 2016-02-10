using Uno;
using Uno.IO;
using Uno.Net.Sockets;

namespace Uno.Net.Http
{
    public class SslThing
    {
        public static bool SetupSecureStream(HttpRequest request, NetworkStream stream, Socket socket, out NetworkStream outStream)
        {
            outStream = null;
            // https://tools.ietf.org/html/rfc2818 <- replaced by https://tools.ietf.org/html/rfc7230
            /*var sslStream = new SslStream(stream, false, UserCertificateValidationCallback, null, EncryptionPolicy.RequireEncryption);
            outStream = sslStream;
            try
            {
                sslStream.AuthenticateAsClient(request.Uri.Host);

            }
            catch (AuthenticationException e)
            {
                debug_log("Exception: {0}", e.Message);
                socket.Close();
                return true;
            }*/

            return false;
        }
        
        /*static bool UserCertificateValidationCallback(object sendePr, X509Certificate certificate, X509Chain chain, SslPolicyErrors sslPolicyErrors)
        {
            if (sslPolicyErrors == SslPolicyErrors.None)
                return true;

            debug_log("Certificate error: {0}", sslPolicyErrors);

            // Do not allow this client to communicate with unauthenticated servers.
            return false;
        }*/
    }
}