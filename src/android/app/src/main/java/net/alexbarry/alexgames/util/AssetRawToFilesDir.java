package net.alexbarry.alexgames.util;

import android.content.Context;
import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.util.Log;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;

public class AssetRawToFilesDir {

    private final static String TAG = "AssetRawToFilesDir";

    private AssetRawToFilesDir() { }

    public static void copyFromAssetsToFiles(Context context, String name) {
        Log.i(TAG, "copyFromAssetsToFiles");
        File dst = context.getFilesDir();
        String[] files;
        try {
            files = context.getAssets().list(name);
        } catch (IOException e) {
            Log.e(TAG, "IOException getting assets list", e);
            return;
        }

        AssetManager assets = context.getAssets();
        int filesCopied = 0;
        try {
            filesCopied = copyFromAssetsDirToFiles(assets, name, dst);
        } catch (IOException e) {
            Log.e(TAG, String.format("IOException"), e);
            return;
        }
        Log.i(TAG, String.format("Copied %d files", filesCopied));
    }
    
    private static int copyFromAssetsDirToFiles(AssetManager assets, String path, File dst) throws IOException {
        int filesCopied = 0;
        //Log.d(TAG, String.format("mkdirs: %s", dst.getAbsolutePath()));
        dst.mkdirs();
        String[] files = assets.list(path);
        //Log.d(TAG, String.format("path %s, len =%d, dst: %s", path, files.length, dst.getAbsolutePath()));
        if (files.length == 0) {
            File dst2 = new File(dst, path);
            copyFileFromAssets(assets, dst2, path);
            filesCopied++;
        } else {
            File dst_dir = new File(dst, path);
            // Log.d(TAG, String.format("creating dir %s", dst_dir.getAbsolutePath()));
            dst_dir.mkdirs();
            for (String file : files) {
                String full_path = path + "/" + file;
                filesCopied += copyFromAssetsDirToFiles(assets, full_path, dst);
            }
        }
        return filesCopied;
    }

    private static void copyFileFromAssets(AssetManager assets, File dst, String file) throws IOException {
        //Log.d(TAG, String.format("copying file: %s", file));
        InputStream inputStream = assets.open(file);

        OutputStream outputStream;

        //Log.d(TAG, String.format("creating new file at %s", dst.getAbsolutePath()));
        dst.createNewFile();
        outputStream = new FileOutputStream(dst);

        final int CHUNK_SIZE = 4096;
        try {
            byte[] buff = new byte[4096];
            int bytesRead;
            do {
                bytesRead = inputStream.read(buff);
                outputStream.write(buff, 0, bytesRead);
            } while (bytesRead == CHUNK_SIZE);
        } finally {
            inputStream.close();
        }
        outputStream.close();
    }
}
