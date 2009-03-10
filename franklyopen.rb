require 'rubygems'
require 'sinatra'
require 'pathname'
require 'openid'
require 'openid/store/filesystem'

include OpenID::Server

def process(params)
  store = OpenID::Store::Filesystem.new(Pathname.new(__FILE__).parent.join('store'))
  server = Server.new(store, 'http://localhost:4567/')
  oidreq = server.decode_request(params)
  
  if !oidreq
    return erb :index
  end
  
  oidresp = nil
  if oidreq.kind_of?(CheckIDRequest)
    identity = oidreq.identity
    if oidreq.id_select
      identity = 'http://localhost:4567/'
    end
    
    if oidresp
      nil
    else
      oidresp = oidreq.answer(true, nil, identity)
    end
  else
    oidresp = server.handle_request(oidreq)
  end
  
  if oidresp.needs_signing
    signed_response = server.signatory.sign(oidresp)
  end
  web_response = server.encode_response(oidresp)
  case web_response.code
  when HTTP_OK
    web_response.body
  when HTTP_REDIRECT
    redirect(web_response.headers['location'])
  end
end

get '/' do
  process(params)
end

post '/' do
  process(params)
end

__END__

@@ index
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
<head>
<title>sinatra-openid</title>
<link rel="openid.server" href="http://localhost:4567/" />
<link rel="openid.delegate" href="http://localhost:4567/" />
</head>
<body>
<p>This is an OpenID server endpoint.</p>
</body>
</html>
