---
title: CS193p, iOS developing with Swift, Class 1
date: 2017-01-15 02:35:33
tags: [ios, cs193p]
---

- introduction to iOS environment
- initial files
- hello world
- function
- a calculator
- variable
- optional: Type



---


# iOS system layers

- Cocoa Touch: UI/Objects: multi-touch, motion, view hierarchy, web view, camera;
- Media: OpenAL, Core Audio, PDF;
- Core Services: Core Services: collections, networking, file access;
- Core OS (bottom): Unix;


# platform

- Tools: Xcode
- Language: 1. swift 2. obj-c

# initial files

- assets.xcassets: Media files: icon, sounds, images
- ViewController.swift: Controller in MVC
- Main.storyboard: View in MVC, edit it just with mouse

## ViewController.swift

- `import UIKit` import a module, like Java; `Foundation` is another important module
- `class ViewController: UIViewController`: `: UIViewController` inherits form `UIViewController`; all MVC controllers inherits from `UIViewController`, either directly or indirectly;

## Main.storyboard

- Components: from 

![/images/cs193p/ios_components_panel.png](/images/cs193p/ios_components_panel.png)


# Hello world!

Clear the ViewController.swift, like this:
```
import UIKit
class ViewController: UIViewController {}
```

Add a button: In the view, components panel, drug a button to the “screen”

Show the assistant editor on the right: Click on

![/images/cs193p/ios_assistant_editor_button.png](/images/cs193p/ios_assistant_editor_button.png)

Add an action: holding down the `control`, drug the button to the code

![/images/cs193p/ios_button_add_function.png](/images/cs193p/ios_button_add_function.png)

Function editing: the connection should be `action`, the arguments should be `sender`(the button being touched itself); change the Type to `UIButton`, the sender is expected to be an `UIButton`; event for `touch up inside` means “after push down and loosen it”, simply a click.


## First Function

```swift
@IBAction func touchDigit(_ sender: UIButton) {}
```

- `@IBAction`: label, not a part of function;
- `func`: this is the function on a class; `func` can be add outside of the `{}`(a class), to be a Globe Function; 
- `touchDigit` is the function’s name; 
- `()`is the parameters; 
- `_` is used to define that the parameter has no external name (more on [stackoverflow](http://stackoverflow.com/questions/30876068/what-is-in-swift-telling-me) ); 
- `sender` is the para name, `UIButton` is its type (use `:` to define its type);

Add a return. it can be like this:
```swift
@IBAction func touchDigit(_ sender: UIButton) -> Double{…}
```

add a `-> Double`;

Add another argument. like this: 

```swift
(_ sender: UIButton, anotherPara: Int)
```
 
the Type here is a Integer.


### Call this function

```swift
Object.touchDigit(someButton, anotherPara: 5)
```

Do clarify the name of the parameters! Like `anotherPara: 5`. the `anotherPara:` should not be ignored; but the first argument must be ignored. (see below)

Diff between `(sender: UIButton)` and `(_ sender: UIButton)`: 
- 1st **MUST** be called like `.funcName(sender: self, anotherPara: 5)`; 
- 2nd with `_` **MUST** be called like `.funcName((self, anotherPara: 5)`

Call `self`: `self.function(para, para)`, `self`is THIS object.

## Add statement:

```swift
@IBAction func touchDigit(_ sender: UIButton) {
    print("hello world!")
}
```
    
do not need `;` at the end of the line. If need two statements on the same line, you should add a `;`;
    
Run!

![/images/cs193p/ios_run_hello_world.png](/images/cs193p/ios_run_hello_world.png)

# A Calculator

Add a `var`: `var digit = 1`; `var` and `let` can define a variable.

## var

Diff `var` & `let`: 

- `var` is a variable;
- `let` define a **READ-ONLY**  variable 
    - is clear to read: it’s a **constant**; 
    - if use the Array or Dictionary, `let` means nothing can be taken out or into, it’s **READ-ONLY**.

*Reference for Objects or Functions: press `option` and click.* 

get UIButton’s title: `UIButton.currentTitle`. it’s a property, can only be `get`;

> The current title that is displayed on the button.
> `var currentTitle: String? { get }`

Print something: `print("touched \(digit) digit”)`. use `\(variable_name_here)` to as a replacer.
* when run the statement `print("touched \(digit) digit”)`, we get this output: `touched Optional("5") digit`. So what is `Optional()`?

we **MUST** always initialize a variable with a initial value. otherwise, we will get a ERROR. Except for `Optional`, it has a default value: “not set”, aka `nil`.  

we can init a variable by:
```
var a: bool = false
// var a = false
```

2nd line is good enough cause `false` can only be a `bool`:

![/images/cs193p/ios_var_lake_of_type.png](/images/cs193p/ios_var_lake_of_type.png)

## optional: Type

Back to the API doc:
```swift
var currentTitle: String? { get }
```

we get a `?` after `String`.  `String?` is a Type, like `int` or `bool`. 
An `optional` has two values:
- Not set. in Swift, it’s `nil`. means this `optional` is not set.
* Set. it has an “associate value”, can be any Type, like `int` or `double`. 

`String?` means this is an `optional`, whose “associate value” is a `String`; we call it “optional string”.

we `let var = var: String?`, it will be also a optional String: 

![/images/cs193p/ios_let_var_optional_string.png](/images/cs193p/ios_let_var_optional_string.png)

### Why we need an `optional`?

A button can have no title.  When we get its title, it print like this:
```
touched Optional("3") digit
touched nil digit
```

it might have no value, aka a `nil`. 

Why not a `0`? If the variable has no value, create a `””`(empty string) for a `String`) or a `0` for a `int`. But it’s not cover all the cases. “empty string” is different between “not set”. We can set a `String` to `””`, we can not judge a String from “empty” from “either set”. 

But we do not need a String?: `Optional(“3”)`, we need a `”3”`. We can simply put:
```swift
let digit = sender.currentTitle!
```

we add a `!` after a `?` Type, aka the optional Type, to unwrap it.

After `!`, we unzip a `option` Type. If the optional is currently a `nil`, the App will **CRASH**. 

```
fatal error: unexpectedly found nil while unwrapping an Optional value
```

But it’s a good thing, because it’s very informative.  So the the variable becomes a `String`: 

![/images/cs193p/ios_let_var_unzip_optional.png](/images/cs193p/ios_let_var_unzip_optional.png)


### Set an optional

we can set an `option` to `nil` by:
```swift
var1 = nil
```

we set  an `option`’s “associate value” by:
```swift
var1 = 1
```

if the `var1` is an `optional`, this will change its “associate value”. 

### Declare an optional

```swift
var display: UILabel!
// var display: UILabel?
```

you can either declare it with `!` or `?`. 

Diff:
- `!` will automatically and implicitly unwrap this `optional` everywhere. When we call a `var2!`, it should be `var2`.
* `?` will **not** implicitly unwrap. So we call `var2?` by `var2!`

### if optional

`let mathSymbol = sender.currentTitle!` is too risky, it might cause crash. So we use:
```swift
if let mathSymbol = sender.currentTitle {
}
```

*`if` statement do not have `()`*

In this case, `if` means “if this currentTitle has value(associate value)”, aka “if this `currentTitle?` is not `nil`”  then `let mathSymbol = sender.currentTitle!`

outside this statement `if .. {}` this `mathSymbol` will not even be defined. 


## if equal

```swift
if mathSymbol == "π" {
    display.text = String(M_PI)
}
```

`String()` initialize a new String Object. 

![/images/cs193p/ios_m_pi.png](/images/cs193p/ios_m_pi.png)

## Remove A Function From A Button

When we copy a button, we copy its parameters like title, size, and also, the functions it relates. But we may need to remove the linkers.

Right click on a button:

![/images/cs193p/ios_button_remove_function.png](/images/cs193p/ios_button_remove_function.png)


we can click on the “x” button to remove this button’s function. 

## Auto Shrink Font Size On Label 

![/images/cs193p/ios_label_autoshrink.png](/images/cs193p/ios_label_autoshrink.png)

set the minimum font size. if the text is too long, it will automatically shrink the font to contain more numbers. 

![/images/cs193p/ios_label_shrink_result.jpg](/images/cs193p/ios_label_shrink_result.jpg)