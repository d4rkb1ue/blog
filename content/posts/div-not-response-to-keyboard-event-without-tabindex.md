---
title: DOM No Response To Keyboard Event
date: 2017-06-16 15:25:49
tags: [JavaScript, Web]
---

# Register onKeyDownListener on HTML Element

```html
<!DOCTYPE html>
<html>
<head>
  <script src="../build/react.js"></script>
  <script src="../build/react-dom.js"></script>
  <script src="../build/browser.min.js"></script>
</head>
<body>
  <div id="app"></div>
  <script type="text/babel">
class App extends React.Component {
  handleKeyDown(event) {
    console.log('handling a key press');
  }
  render() {
    return (
      <div onKeyDown={this.handleKeyDown}>
        here!
      </div>
    );
  }
}
ReactDOM.render(<App />, document.getElementById('app'));
</script>
</body>
</html>
```

There are NO response here. You press any thing and there is NO response. It's doesn't matter you mouse focus on div or not.



# Add tabIndex

Try add this,

```jsx
<div onKeyDown={this.handleKeyDown}
     tabIndex={0}>
  here!
</div>
```
`tabIndex={0}` and we are done!

Another interesting thing is that the div element will gain a 

```css
#app:focus {
  outline: -webkit-focus-ring-color auto 5px;
}
```

In the same time you set a `tabIndex` attribute. That's actually an indicator that you can make keyboard event on this. Use this to surpress:

```jsx
<div onKeyPress={this.handleKeyDown}
     tabIndex={0}
     style={{outline: 'none'}}>
  here!
</div>
```

Done!

# Reason

[StackOverflow - React not responding to key down event](https://stackoverflow.com/questions/32255075/react-not-responding-to-key-down-event)

> it's the only way elements beside links and form elements can receive keyboard focus and thus key presses. It's set to zero so that it doesn't override the native tab order. 


# More interesting

If you use `onKeyPress` listener, you will miss the `Esc` key press event.

```jsx
onKeyPress={this.handleKeyDown}
```

Press `Esc` on this will trigger nothing. Try `onKeyUp` or `onKeyDown` instead.

## Reason

> keydownwill mimic native behaviour - at least on Windows where pressing ESC or Return in a dialog will trigger the action before the key is released.

# Ref

- [StackOverflow - React not responding to key down event](https://stackoverflow.com/questions/32255075/react-not-responding-to-key-down-event)

- [Keyboard Accessibility](http://webaim.org/techniques/keyboard/tabindex)

- [StackOverflow - Which keycode for escape key with jQuery](https://stackoverflow.com/questions/1160008/which-keycode-for-escape-key-with-jquery)

