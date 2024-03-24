package net.alexbarry.alexgames

import android.annotation.SuppressLint
import android.net.Uri
import android.os.Bundle
import android.util.Log
import androidx.fragment.app.Fragment
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.webkit.WebViewAssetLoader

// TODO: Rename parameter arguments, choose names that match
// the fragment initialization parameters, e.g. ARG_ITEM_NUMBER
private const val ARG_PARAM1 = "param1"
private const val ARG_PARAM2 = "param2"

/**
 * A simple [Fragment] subclass.
 * Use the [LocalClientWebView.newInstance] factory method to
 * create an instance of this fragment.
 */
class LocalClientWebView : Fragment() {
    private val TAG = "LocalClientWebView"
    // TODO: Rename and change types of parameters
    private var param1: String? = null
    private var param2: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        arguments?.let {
            param1 = it.getString(ARG_PARAM1)
            param2 = it.getString(ARG_PARAM2)
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        // Inflate the layout for this fragment
        val view = inflater.inflate(R.layout.fragment_local_client_web_view, container, false)

        val assetLoader = WebViewAssetLoader.Builder()
            .addPathHandler("/assets/", WebViewAssetLoader.AssetsPathHandler(requireContext()))
            .build()
        val webview = view.findViewById<WebView>(R.id.local_client_web_view)
        webview.settings.javaScriptEnabled = true
        webview.settings.domStorageEnabled = true // needed for window.localStorage

        // False because this is not needed now that I'm using the WebViewAssetLoader
        webview.settings.allowFileAccessFromFileURLs = false

        // False, even without the WebViewAssetLoader, `allowFileAccessFromFileURLs` is enough
        webview.settings.allowUniversalAccessFromFileURLs = false

        //webview.loadUrl("file:///android_asset/html/index.html")
        webview.loadUrl("https://appassets.androidplatform.net/assets/html/index.html?no_ws=true")
        //webview.loadUrl("https://appassets.androidplatform.net/assets/html/index.html")

        webview.webViewClient = object : WebViewClient() {
            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                Log.i(TAG, "onPageFinished");
                webview.evaluateJavascript("set_header_visible(false);", null);
            }

            override fun shouldInterceptRequest(
                view: WebView?,
                request: WebResourceRequest?
            ): WebResourceResponse? {
                return if (request != null) {
                    assetLoader.shouldInterceptRequest(request.url)
                } else {
                    null
                }
            }

            @Suppress("DEPRECATION")
            override fun shouldInterceptRequest(
                view: WebView?,
                url: String?
            ): WebResourceResponse? {
                return assetLoader.shouldInterceptRequest(Uri.parse(url))
            }
        }

        //webview.loadUrl("http://localhost:55080")
        return view
    }

    /*
    override fun onResume() {
        Log.i(TAG, "onResume")
        val webview = requireView().findViewById<WebView>(R.id.local_client_web_view)
        webview.loadUrl("file:///android_asset/html/index.html")
        webview.reload()
        super.onResume()
    }
     */

    companion object {
        /**
         * Use this factory method to create a new instance of
         * this fragment using the provided parameters.
         *
         * @param param1 Parameter 1.
         * @param param2 Parameter 2.
         * @return A new instance of fragment LocalClientWebView.
         */
        // TODO: Rename and change types and number of parameters
        @JvmStatic
        fun newInstance(param1: String, param2: String) =
            LocalClientWebView().apply {
                arguments = Bundle().apply {
                    putString(ARG_PARAM1, param1)
                    putString(ARG_PARAM2, param2)
                }
            }
    }
}