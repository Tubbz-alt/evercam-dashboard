(function(){var e;e=function(e){var t,r;return r=/^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/,t=/^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/,r.test(e)||t.test(e)},$(function(){return $("#camera-url-web").on("input",function(){var e,t;return t=$(this).val(),e=document.createElement("a"),e.href=t,$(this).val(e.hostname),$("#port-web").val(e.port),$("#snapshot-web").val(e.pathname)}),$("#test").click(function(t){var r,a,n,s,o,l,c,i,u;return n=/^\d+$/,i=$("#port").val(),a=$("#camera-url").val(),r=$("#snapshot"),o=r.val(),0===o.indexOf("/")&&(r.val(o.substring(1)),o=r.val()),o=o.replace(/\?/g,"X_QQ_X").replace(/&/g,"X_AA_X"),t.preventDefault(),""!==i&&(!n.test(i)||i>65535)?void $("#test-error").text("Port value is incorrect"):(""!==i&&(i=":"+i),""!==a&&e(a)?0===a.indexOf("192.168")||0===a.indexOf("127.0.0")||0===a.indexOf("10.")?void $("#test-error").text("This is local IP. Please use external IP."):(c=["external_url=http://"+a+i,"jpg_url=/"+o,"cam_username="+$("#camera-username").val(),"cam_password="+$("#camera-passord").val()],l=Ladda.create(this),l.start(),u=0,s=setInterval(function(){return u=Math.min(u+.025,1),l.setProgress(u),1===u?(l.stop(),clearInterval(s)):void 0},200),$.getJSON(EVERCAMP_API+"cameras/test.json?"+c.join("&")).done(function(e){return console.log("success"),$("#test-error").text("We got a snapshot"),$("#testimg").attr("src",e.data)}).fail(function(e){return $("#test-error").text(e.responseJSON.message),console.log("error")}).always(function(){return l.stop(),clearInterval(s)})):void $("#test-error").text("External URL is incorrect"))})})}).call(this);