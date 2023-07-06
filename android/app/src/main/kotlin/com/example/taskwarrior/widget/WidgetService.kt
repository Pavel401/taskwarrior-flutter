package com.example.taskwarrior.widget
import android.content.Intent
import android.widget.RemoteViewsService
import com.example.taskwarrior.widget.ExploreViewsFactory

class WidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return ExploreViewsFactory(
            this.applicationContext,
            intent
        )
    }
}