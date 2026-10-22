package com.kapsgrafix.milkekhelo;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

/** Shows the details of a crash (see {@link CrashCatcher}) with a Share button. */
public class CrashActivity extends Activity {
  @Override
  protected void onCreate(Bundle state) {
    super.onCreate(state);
    final String trace = getIntent().getStringExtra("trace") == null ? "(no details)" : getIntent().getStringExtra("trace");
    int pad = (int) (16 * getResources().getDisplayMetrics().density);

    LinearLayout root = new LinearLayout(this);
    root.setOrientation(LinearLayout.VERTICAL);
    root.setPadding(pad, pad * 3, pad, pad);
    root.setBackgroundColor(Color.WHITE);

    TextView title = new TextView(this);
    title.setText("MilkeKhelo crashed — screenshot this or tap Share and send it to Claude");
    title.setTextSize(16);
    title.setTextColor(Color.BLACK);
    root.addView(title);

    Button share = new Button(this);
    share.setText("Share crash details");
    share.setOnClickListener(v -> {
      Intent send = new Intent(Intent.ACTION_SEND);
      send.setType("text/plain");
      send.putExtra(Intent.EXTRA_TEXT, trace);
      startActivity(Intent.createChooser(send, "Share crash details"));
    });
    root.addView(share);

    TextView body = new TextView(this);
    body.setText(trace);
    body.setTextSize(11);
    body.setTextColor(Color.DKGRAY);
    body.setTextIsSelectable(true);
    ScrollView scroll = new ScrollView(this);
    scroll.addView(body);
    root.addView(scroll, new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f));

    setContentView(root);
  }
}
