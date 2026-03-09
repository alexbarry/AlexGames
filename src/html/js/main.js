import {basicSetup} from "codemirror"
import {EditorView} from "@codemirror/view"

const view = new EditorView({
  doc: "Start document",
  parent: document.getElementById('editor'),
  extensions: [basicSetup]
})

export function update_lua_editor(content) {
	view.dispatch({
		changes: { from: 0, to: view.state.doc.length, insert: content }
	});
}

export function get_editor_contents() {
	return view.state.doc.toString();
}
