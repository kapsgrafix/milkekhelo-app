package com.kapsgrafix.milkekhelo;

import android.content.ContentProvider;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;

import java.io.PrintWriter;
import java.io.StringWriter;

/**
 * Starts before everything else in the app (highest initOrder) and catches
 * any crash, showing its details on a simple screen ({@link CrashActivity})
 * instead of Android's "keeps stopping" box — so a crash can be
 * screenshotted and fixed. Copied into the app by the CI workflow.
 */
public class CrashCatcher extends ContentProvider {
  @Override
  public boolean onCreate() {
    final Context ctx = getContext();
    final Thread.UncaughtExceptionHandler previous = Thread.getDefaultUncaughtExceptionHandler();
    Thread.setDefaultUncaughtExceptionHandler(new Thread.UncaughtExceptionHandler() {
      @Override
      public void uncaughtException(Thread thread, Throwable error) {
        try {
          StringWriter sw = new StringWriter();
          error.printStackTrace(new PrintWriter(sw));
          String text = "Android " + Build.VERSION.RELEASE + " (API " + Build.VERSION.SDK_INT + "), "
              + Build.MANUFACTURER + " " + Build.MODEL + "\nThread: " + thread.getName() + "\n\n" + sw;
          if (text.length() > 60000) text = text.substring(0, 60000);
          Intent i = new Intent(ctx, CrashActivity.class);
          i.putExtra("trace", text);
          i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
          ctx.startActivity(i);
        } catch (Throwable ignored) {
          if (previous != null) previous.uncaughtException(thread, error);
          return;
        }
        android.os.Process.killProcess(android.os.Process.myPid());
        System.exit(10);
      }
    });
    return true;
  }

  @Override public Cursor query(Uri u, String[] p, String s, String[] a, String o) { return null; }
  @Override public String getType(Uri u) { return null; }
  @Override public Uri insert(Uri u, ContentValues v) { return null; }
  @Override public int delete(Uri u, String s, String[] a) { return 0; }
  @Override public int update(Uri u, ContentValues v, String s, String[] a) { return 0; }
}
