# Правила минификации.
#
# Flutter-приложение почти целиком живёт в собственном движке, и Java-кода в
# нём мало — но R8 всё равно выбрасывает то, к чему обращаются только через
# рефлексию или из нативного кода. Ниже перечислено ровно это.

# Движок Flutter и его плагины: вызовы идут из нативного кода, R8 их не видит.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# camera и image_picker обращаются к классам androidx через рефлексию.
-keep class androidx.lifecycle.** { *; }
-keep class androidx.camera.** { *; }

# Аннотации и сигнатуры дженериков нужны сериализации json.
-keepattributes Signature, *Annotation*, InnerClasses, EnclosingMethod

# Номера строк в стектрейсах: без них отчёт о падении бесполезен, а стоит
# это десяток килобайт. Имена файлов при этом обезличиваются.
-keepattributes SourceFile, LineNumberTable
-renamesourcefileattribute SourceFile
