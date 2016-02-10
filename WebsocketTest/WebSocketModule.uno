using Fuse;
using Uno;
using Fuse.Scripting;
using Fuse.Reactive;

namespace WebSocketTest
{
	public class WebSocketModule : NativeModule
	{
    	Uno.Net.BrowserWebsocketApi _ws;
		NativeEvent _onmessage;
		NativeEvent _onopen;
		NativeEvent _onerror;
		bool _jsInitialized;

    	public WebSocketModule()
    	{
    		AddMember(new NativeFunction("connect",  (NativeCallback)Connect));
			AddMember(new NativeFunction("send", (NativeCallback)Send));
			AddMember(new NativeFunction("close", (NativeCallback)Close));

			_onmessage = new NativeEvent("onmessage");
			AddMember(_onmessage);

			_onopen = new NativeEvent("onopen");
			AddMember(_onopen);

			_onerror = new NativeEvent("onerror");
			AddMember(_onerror);
			Evaluated += OnJsInitialized;
    	}
		
		void OnJsInitialized(object sender, Uno.EventArgs args)
		{
			_jsInitialized = true;
			Uno.Platform2.Application.Terminating += OnTerminating;
		}
        
		void OnTerminating(Uno.Platform2.ApplicationState newState)
		{
        	debug_log("OnTerminating");
        	_ws.Dispose();
        }

		object Connect(Context c, object[] args)
		{
			var uri = args[0] as string;
			_ws = new Uno.Net.BrowserWebsocketApi(new Uno.Net.Http.Uri(uri));
			_ws.onmessage = onmessage;
			_ws.onopen = onopen;
			_ws.onerror = onerror;

			return null;
		}

		object Close(Context c, object[] args)
		{
			debug_log "CLOSE";
        	_ws.close();
			return null;
		}

		object Send(Context c, object[] args)
		{
			var data = args[0] as string;
			_ws.send(data);
			return null;
		}

		void onopen()
		{
			_onopen.RaiseAsync();
		}

		void onerror(string message)
		{
			_onerror.RaiseAsync(message);
		}
    	
    	void onmessage(string data)
    	{
    		var obj = _onmessage.Context.NewObject();
    		obj["data"] = data;
			_onmessage.RaiseAsync(obj);
    	}
	}
}