//
//  v002UniqueClassNames.h
//  HelperAppTest
//
//  Created by Tom Butterworth on 02/08/2011.
//  Copyright 2011 Tom Butterworth. All rights reserved.
//


/*
 Use a preprocessor macro in build settings to define
 
 V002_UNIQUE_CLASS_NAME_PREFIX=MyPrefix
 
 Alternatively define
 
 V002_CLASS_NAMES_PRODUCT_IS_APP
 
 to use straight class names for app code ONLY.
 ALWAYS use the prefix when building loadable code (eg plugin, bundle).
 
 The rest, including class aliases, will happen automatically
 */
#ifndef v002UniqueClassNames_h
#define v002UniqueClassNames_h

#define V002_CONCAT(x, y) V002_CONCAT_EXPANDED(x, y)
#define V002_CONCAT_EXPANDED(x, y) x ## y
#define V002_SYMBOL_FROM_CLASS_NAME(NAME) V002_CONCAT(.objc_class_name_, NAME)

#ifdef V002_UNIQUE_CLASS_NAME_PREFIX
#define V002_UNIQUE_CLASS_NAME(CLASS_NAME) V002_CONCAT(V002_UNIQUE_CLASS_NAME_PREFIX, CLASS_NAME)
#define V002_UNIQUE_CLASS_SYMBOL(CLASS_NAME) V002_SYMBOL_FROM_CLASS_NAME(V002_UNIQUE_CLASS_NAME(CLASS_NAME))
#define V002_USE_CLASS_ALIAS
#else
#ifndef V002_CLASS_NAMES_PRODUCT_IS_APP
#warning Neither V002_UNIQUE_CLASS_NAME_PREFIX nor V002_CLASS_NAMES_PRODUCT_IS_APP is defined. Define one or the other as a preprocessor macro in build settings.
#endif
#define V002_UNIQUE_CLASS_NAME(CLASS_NAME) CLASS_NAME
#define V002_UNIQUE_CLASS_SYMBOL(CLASS_NAME) V002_SYMBOL_FROM_CLASS_NAME(CLASS_NAME)
#endif


#endif
