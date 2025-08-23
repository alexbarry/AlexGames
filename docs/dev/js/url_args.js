var URL_args = function () {
  var query_string = {};
  var query = window.location.search.substring(1);
  var vars = query.split("&");
  for (var i=0;i<vars.length;i++) {
    var pair = vars[i].split("=");
        // If first entry with this name
    if (typeof query_string[pair[0]] === "undefined") {
      query_string[pair[0]] = decodeURIComponent(pair[1]);
        // If second entry with this name
    } else if (typeof query_string[pair[0]] === "string") {
      var arr = [ query_string[pair[0]],decodeURIComponent(pair[1]) ];
      query_string[pair[0]] = arr;
        // If third or later entry with this name
    } else {
      query_string[pair[0]].push(decodeURIComponent(pair[1]));
    }
  }
    return query_string;
}();


var URL_noargs = window.location.href.split('?')[0];

function set_url_args(str) {
	// Note that this causes a page reload. Not ideal if preventable
	//window.location.href = URL_noargs + "?" + str;

	let new_url = URL_noargs + "?" + str;
	// This updates the URL and back stack, but does not refresh the page
	window.history.pushState({page: 1}, document.title, new_url);
}
