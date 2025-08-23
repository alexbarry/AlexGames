
function init_collapsables() {
	console.debug("init_collapsables");
	let elems = document.getElementsByClassName("collapsable");
	for (let elem of elems) {
		elem.addEventListener('click', (e) => {
			console.debug("elem", elem, "clicked, toggling collapsable");
			if (elem.classList.contains("collapsed")) {
				elem.classList.remove("collapsed");
			} else {
				elem.classList.add("collapsed");
			}
		});
	}
}
