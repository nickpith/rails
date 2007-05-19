require File.dirname(__FILE__) + '/../abstract_unit'
require 'action_controller/cgi_process'

class BaseCgiTest < Test::Unit::TestCase
  def setup
    @request_hash = {"HTTP_MAX_FORWARDS"=>"10", "SERVER_NAME"=>"glu.ttono.us:8007", "FCGI_ROLE"=>"RESPONDER", "HTTP_X_FORWARDED_HOST"=>"glu.ttono.us", "HTTP_ACCEPT_ENCODING"=>"gzip, deflate", "HTTP_USER_AGENT"=>"Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/312.5.1 (KHTML, like Gecko) Safari/312.3.1", "PATH_INFO"=>"", "HTTP_ACCEPT_LANGUAGE"=>"en", "HTTP_HOST"=>"glu.ttono.us:8007", "SERVER_PROTOCOL"=>"HTTP/1.1", "REDIRECT_URI"=>"/dispatch.fcgi", "SCRIPT_NAME"=>"/dispatch.fcgi", "SERVER_ADDR"=>"207.7.108.53", "REMOTE_ADDR"=>"207.7.108.53", "SERVER_SOFTWARE"=>"lighttpd/1.4.5", "HTTP_COOKIE"=>"_session_id=c84ace84796670c052c6ceb2451fb0f2; is_admin=yes", "HTTP_X_FORWARDED_SERVER"=>"glu.ttono.us", "REQUEST_URI"=>"/admin", "DOCUMENT_ROOT"=>"/home/kevinc/sites/typo/public", "SERVER_PORT"=>"8007", "QUERY_STRING"=>"", "REMOTE_PORT"=>"63137", "GATEWAY_INTERFACE"=>"CGI/1.1", "HTTP_X_FORWARDED_FOR"=>"65.88.180.234", "HTTP_ACCEPT"=>"*/*", "SCRIPT_FILENAME"=>"/home/kevinc/sites/typo/public/dispatch.fcgi", "REDIRECT_STATUS"=>"200", "REQUEST_METHOD"=>"GET"}
    # cookie as returned by some Nokia phone browsers (no space after semicolon separator)
    @alt_cookie_fmt_request_hash = {"HTTP_COOKIE"=>"_session_id=c84ace84796670c052c6ceb2451fb0f2;is_admin=yes"}
    @fake_cgi = Struct.new(:env_table).new(@request_hash)
    @request = ActionController::CgiRequest.new(@fake_cgi)
  end

  def default_test; end
end


class CgiRequestTest < BaseCgiTest
  def test_proxy_request
    assert_equal 'glu.ttono.us', @request.host_with_port
  end

  def test_http_host
    @request_hash.delete "HTTP_X_FORWARDED_HOST"
    @request_hash['HTTP_HOST'] = "rubyonrails.org:8080"
    assert_equal "rubyonrails.org:8080", @request.host_with_port

    @request_hash['HTTP_X_FORWARDED_HOST'] = "www.firsthost.org, www.secondhost.org"
    assert_equal "www.secondhost.org", @request.host
  end

  def test_http_host_with_default_port_overrides_server_port
    @request_hash.delete "HTTP_X_FORWARDED_HOST"
    @request_hash['HTTP_HOST'] = "rubyonrails.org"
    assert_equal "rubyonrails.org", @request.host_with_port
  end

  def test_host_with_port_defaults_to_server_name_if_no_host_headers
    @request_hash.delete "HTTP_X_FORWARDED_HOST"
    @request_hash.delete "HTTP_HOST"
    assert_equal "glu.ttono.us:8007", @request.host_with_port
  end

  def test_host_with_port_falls_back_to_server_addr_if_necessary
    @request_hash.delete "HTTP_X_FORWARDED_HOST"
    @request_hash.delete "HTTP_HOST"
    @request_hash.delete "SERVER_NAME"
    assert_equal "207.7.108.53:8007", @request.host_with_port
  end

  def test_cookie_syntax_resilience
    cookies = CGI::Cookie::parse(@request_hash["HTTP_COOKIE"]);
    assert_equal ["c84ace84796670c052c6ceb2451fb0f2"], cookies["_session_id"]
    assert_equal ["yes"], cookies["is_admin"]

    alt_cookies = CGI::Cookie::parse(@alt_cookie_fmt_request_hash["HTTP_COOKIE"]);
    assert_equal ["c84ace84796670c052c6ceb2451fb0f2"], alt_cookies["_session_id"]
    assert_equal ["yes"], alt_cookies["is_admin"]
  end
end


class CgiRequestParamsParsingTest < BaseCgiTest
  def test_doesnt_break_when_content_type_has_charset
    data = 'flamenco=love'
    @request.env['CONTENT_LENGTH'] = data.length
    @request.env['CONTENT_TYPE'] = 'application/x-www-form-urlencoded; charset=utf-8'
    @request.env['RAW_POST_DATA'] = data
    assert_equal({"flamenco"=> "love"}, @request.request_parameters)
  end
end
