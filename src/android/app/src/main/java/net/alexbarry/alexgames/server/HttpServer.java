package net.alexbarry.alexgames.server;


import android.content.Context;
import android.util.Log;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.InputStream;
import java.io.InputStreamReader;

import fi.iki.elonen.NanoHTTPD;

public class HttpServer extends NanoHTTPD {

    private final static String TAG = "HttpServer";

    public interface Callback {
        void httpDownload(String user);
    }

    private final Context context;

    private int pagesServed = 0;
    private Callback onDownloadCallback = null;

    public HttpServer(Context context, int port) {
        super(port);
        this.context = context;
    }

    @Override
    public NanoHTTPD.Response serve(NanoHTTPD.IHTTPSession session) {
        //Log.v(TAG, String.format("received http request, method=%s, uri=%s",
        //        session.getMethod(), session.getUri()));

        String uri = session.getUri();
        if (uri.equals("/")) {
            uri = "/index.html";
        }
        File f = new File(context.getFilesDir(), "html/" + uri);

        //Log.v(TAG, String.format("trying to find file %s", f.getAbsolutePath()));

        if (f.isFile()) {
            //Log.v(TAG, "found file, trying to read...");
            InputStream is = null;
            try {
                is = new FileInputStream(f);
            } catch (FileNotFoundException e) {
                Log.e(TAG, "unable to read file", e);
                return NanoHTTPD.newFixedLengthResponse(Response.Status.INTERNAL_ERROR, "text/html", "something went wrong");
            }
            String mimeType = get_filetype_mime_type(f.getName());
            pagesServed++;
            if (onDownloadCallback != null) {
                String user = session.getRemoteIpAddress(); //getRemoteHostName();
                onDownloadCallback.httpDownload(user);
            }
            return NanoHTTPD.newFixedLengthResponse(Response.Status.OK, mimeType, is, f.length());
        } else {
            Log.w(TAG, String.format("could not find file %s", f.getAbsolutePath()));
            return NanoHTTPD.newFixedLengthResponse(Response.Status.NOT_FOUND, "text/html", "not found");
        }
    }

    public int getHttpDownloads() {
        return pagesServed;
    }

    private static String get_filetype_mime_type(String name) {
        if (name.endsWith(".html")) { return "text/html"; }
        else if (name.endsWith(".js")) { return "text/javascript"; }
        else if (name.endsWith(".css")) { return "text/css"; }
        else if (name.endsWith(".png")) { return "image/png"; }
        else if (name.endsWith(".wasm")) { return "application/wasm"; }
        else { return "application/octet-stream"; }
    }

    public void setOnDownloadCallback(Callback callback) {
        this.onDownloadCallback = callback;
    }
}