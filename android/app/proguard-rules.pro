# Smart Photo Diary ProGuard Rules
# 本番リリース用の難読化設定

# TensorFlow Lite - 機械学習モデル用
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.**

# Flutter Core - フレームワーク保護
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Google Play Core - ストア機能用
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Hive Database - ローカルDB用
-keep class hive.** { *; }
-keep class **$HiveFieldAdapter { *; }

# Dart/Flutter 生成コード
-keep class **.g.dart { *; }

# 一般的なAndroidクラス
-keep class androidx.** { *; }
-keep class com.google.android.material.** { *; }

# 警告を抑制
-dontwarn io.flutter.embedding.**
-dontwarn androidx.**

# デバッグ情報を保持（クラッシュ解析用）
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile