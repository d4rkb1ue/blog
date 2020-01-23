---
title: HTML Tabs 标签页的实现方式和对比
date: 2016-05-12 01:41:14
tags: [CSS, JavaScript, Web]
---

# HTML网页里的Tabs的意义是什么？

- `<div class="content">` 的显示内容

- `<li class="tab">` 类型的按钮，需要通过例如添加 `active` 的方式调节选中状态，通过点击，可以修改 `div.content` 内的内容

*其实可以完全不存在 `ul->div` 1对1的关系。其实是点按一个按钮，更改部分位置的html内容*



# 静态Tabs

**内容直接保存在 响应的 `div` HTML 代码中。**
 
- 在静态 HTML 网页中，tabs的只需要执行隐藏，显示 `<div>`

- 最好可以通过 `/panel#tab*` url的方式直接显示为某一个tab

# 动态Tabs

**如果使用AJAX或者其他异步加载技术，动态的获取 tab 下的内容。**

- 默认 tab。如果直接调用 `/panel` 需要显示什么内容。应该直接显示 `tab1` 下的内容

- 未加载内容的加载方式，时机，和加载后的通知

- 加载内容的前后端分离
    - 使用异步获取 HTML 内容？
    - JSON 内容再动态生成HTML？
    
    
- 已加载内容的删除
    - `$.hide()` 
    - 直接 `$('div').html` 进行替换
    
    
- 已经加载过的内容的再次载入，和删除机制有关
    - 如果直接删除了，那毫无疑问要重新获取
    - 如果没删除，立刻显示并且后台再次ajax，返回再更新内容？还是不再次执行AJAX？
    
    
- 和静态一样，最好可以通过 `/panel#tab1` url的方式直接显示为某一个tab

- 参数传入。在执行AJAX时，可能需要传入诸如`用户Token`，`_id` 等信息，这些信息保存在哪里？
    - 对于其他网页的调用，需要后台 执行 `response.send/render`  提供参数
    - 对于本网页的调研，需要在 HTML 里找到信息做参数，而这个参数应该由首先调用 `/panel#tab*` 的 `response.send/render` 提供并保存在 `location.href` 或者`js硬代码`中。 
    - 对于不指定任何Tab和参数的 `/panel` 调用？拒绝:默认值
    
# 可选解决方案

## 1. [Bootstrap](http://v3.bootcss.com/javascript/#tabs)

### 静态完整案例

```html
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8" />
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<!-- 上述3个meta标签*必须*放在最前面，任何其他内容都*必须*跟随其后！ -->
	<title>
		test
	</title>
	<!-- Bootstrap -->
	<link href="//cdn.bootcss.com/bootstrap/3.3.6/css/bootstrap.min.css" rel="stylesheet">
	<!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
	<script src="//cdn.bootcss.com/jquery/1.11.3/jquery.min.js"></script>
	<!-- Include all compiled plugins (below), or include individual files as needed -->
	<script src="//cdn.bootcss.com/bootstrap/3.3.6/js/bootstrap.min.js"></script>
	<!-- End Bootstrap -->
</head>

<body>
	<div>
		<!-- Nav tabs -->
		<ul class="nav nav-tabs" role="tablist">
			<li role="presentation" class="active"><a href="#home" data-toggle="tab" >Home</a></li>
			<li role="presentation"><a href="#profile" data-toggle="tab" >Profile</a></li>
			<li role="presentation"><a href="#messages" data-toggle="tab" >Messages</a></li>
			<li role="presentation"><a href="#settings" data-toggle="tab" >Settings</a></li>
		</ul>

		<!-- Tab panes -->
		<div class="tab-content">
			<div role="tabpanel" class="tab-pane active" id="home">...home</div>
			<div role="tabpanel" class="tab-pane" id="profile">...profile</div>
			<div role="tabpanel" class="tab-pane" id="messages">...messages</div>
			<div role="tabpanel" class="tab-pane" id="settings">...setting</div>
		</div>
	</div>
</body>

</html>
```

### 优势

- 可以通过指定 `li.active` 和 `div.active` 的方式规定默认的导航活动按钮和显示内容

### 动态实例

```html
<div class="row">
    <!-- Nav tabs -->
    <div class="nav-tabslist">
        <ul class="nav nav-pills nav-stacked col-lg-2" role="tablist">
            <li role="presentation" class=""><a href="#orders" data-toggle="tab">订单</a></li>
            <li role="presentation"><a href="#updates" data-toggle="tab">更新</a></li>
            <li role="presentation"><a href="#settings" data-toggle="tab">设置</a></li>
        </ul>

    </div>

    <!-- Tab panes -->
    <div class="tab-content col-lg-10">
        <div role="tabpanel" class="tab-pane" id="orders"></div>
        <div role="tabpanel" class="tab-pane" id="updates">...updates</div>
        <div role="tabpanel" class="tab-pane" id="settings">...setting</div>
    </div>
    
    <script>
        $(function(){
            $('.nav-pills a[href=\"#orders\"]').click(function(){
            <!-- 使用获取JSON -->
                getJSONorders(location.search.substring("?proj_id=".length),$('#orders'));
            })
            
        })
    </script>
    
</div>
```

对应的JSON获取函数实例(这是一个获取指定产品的所有订单并列表的函数):
```js
var getJSONorders = function (proj_id, jq) {
    url = '/project-orders?proj_id=' + proj_id;
    var jqxhr = $.ajax(url, {
        dataType: 'json'
    }).done(function (json) {
        var orders = JSON.parse(json);
        jq.get(0).innerHTML = "<h2 id=\"h2\" class=\"project-panel-title\">订单列表</h2>"
        +"<div class='table-responsive'>"
        +"<table class='table table-striped table hover'><tr><th>#</th><th>用户ID</th><th>选项</th><th>金额</th><th>支付方式</th><th>状态</th><th>备注</th></tr>";
        
        orders.forEach(function(order,index){
            
            var tr = document.createElement('tr');
            tr.innerHTML = "<td>"+(index+1)+"</td>"
            +"<td>"+order.user_id.substring(18)+"</td>"
            +"<td>"+ ("#"+order.rw_id+": "+order.details.substring(0,5)+"..."+order.details.substring(order.details.length-5)) +"</td>"
            +"<td> ¥"+ order.rw_amout +"</td>"
            +"<td>"+ order.payment +"</td>"
            +"<td>"+ order.status +"</td>"
            +"<td>"+ (order.note || "无") +"</td>";
            
            jq.find("tbody").append(tr);
            
        })
        
    }).fail(function (xhr, status) {
        console.log(xhr.status + " " + status);
    })
}
```


#### 问题

- BS提供的Tab控件不支持 `/panel#tab*` 这样的调用。解决方案：

```html
<!-- 注意放在所有异步加载函数的下面 -->
<script>
    $(function(){
        // tab() 显示该tab click() 执行绑定的异步函数。因此本行应在所有异步设置之后(.click(func) 之后)
        $('.nav-pills a[href=\"'+window.location.hash+"\"]").tab('show').click();
        
        // 当#tab发生变化时的反应
        window.onhashchange = function(){
            $('.nav-tabs a[href=\"'+window.location.hash+"\"]").tab('show');
        };
    })
</script>
```



## 2. [JQuery-ui](https://jqueryui.com/tabs/) 

### 静态完整案例

```html
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>jQuery UI Tabs - Default functionality</title>
    <script src="//code.jquery.com/jquery-1.10.2.js"></script>
    <script src="//code.jquery.com/ui/1.11.4/jquery-ui.js"></script>
    <!-- 注意，需要手动初始化 -->
    <script>
        $(function() {
            $( "#tabs" ).tabs();
        });
    </script>
</head>
<body>
 
<div id="tabs">
    <ul>
        <li><a href="#tabs-1">Nunc tincidunt</a></li>
        <li><a href="#tabs-2">Proin dolor</a></li>
        <li><a href="#tabs-3">Aenean lacinia</a></li>
    </ul>
    <div id="tabs-1">
        tab1
    </div>
    <div id="tabs-2">
        tab2
    </div>
    <div id="tabs-3">
        tab3
    </div>
</div>
 
</body>
</html>
```
#### 优势

- 支持 `/panel#tab-id` 式的调用
- 默认就是 tab 1

### 动态完整实例

```html
<html lang="en">
<head>
	<meta charset="utf-8">
	<title>jQuery UI Tabs - Content via Ajax</title>
	<script src="//code.jquery.com/jquery-1.10.2.js"></script>
	<script src="//code.jquery.com/ui/1.11.4/jquery-ui.js"></script>
	<script>
		$(function() {
			$( "#tabs" ).tabs({
			beforeLoad: function( event, ui ) {
				ui.jqXHR.fail(function() {
				ui.panel.html(
					"Couldn't load this tab. We'll try to fix this as soon as possible. " +
					"If this wouldn't be a demo." );
				});
			}
			});
		});
	</script>
</head>

<body>

	<div id="tabs">
		<ul>
			<li><a href="#tabs-1">Preloaded</a></li>
			
			<li><a href="https://jqueryui.com/resources/demos/tabs/ajax/content1.html">Tab 1</a></li>
			<li><a href="https://jqueryui.com/resources/demos/tabs/ajax/content2.html">Tab 2</a></li>
			<li><a href="https://jqueryui.com/resources/demos/tabs/ajax/content3-slow.php">Tab 3 (slow)</a></li>
			<li><a href="https://jqueryui.com/resources/demos/tabs/ajax/content4-broken.php">Tab 4 (broken)</a></li>
		</ul>
		<div id="tabs-1">
			static contents
		</div>
	</div>

</body>
</html>
```

#### 效果

- 支持 `/panel#tab-id` 式的调用
- 默认就是 tab 1
- AJAX 的链接和内容载入会自动处理，并且在内容载入前，后，保存，都有相应的事件响应函数

#### 问题

对于应用Bootstrap的栅格系统的网页，如果需要让 tabs 和 tab-panel(content) 通过 col-*-* 来定义宽度：

```html
<div class="container profile">
        <div id="profile-row" class="row">
            <div id="tabs" class="profile-menu col-md-2 col-lg-2 col-sm-2">
                <ul class="nav nav-pills nav-stacked">
                    <li role="presentation" class="active"><a href="/back-history">支持过的项目</a></li>
                    <li role="presentation"><a href="/created">创立的项目</a></li>
                </ul>
            </div>
        </div>
    </div>
```

`$ui.tab` 载入的`panel`是载入直接在`div#tabs`下的，如果需要把`tabs`的`style`和`panel`的`style`应用Bootstrap的栅格系统，需要：

把结构从:
```js
div.row>div#tabs>div.ui-tabs-panel
```

改为

``` 
div.row>         div.ui-tabs-panel
```

即将`div.ui-tabs-panel`提升到和`div#tabs`同一层，互为兄弟，这样一来才能正确处理bootstrap的col的栅格（例如`tab.col-3, panel.col-9`)

#### 我的解决方案 

```js
$(function(){
    // 使用 jquery-ui 操作tabs
    $( "#tabs" ).tabs({
        // 在tab.panel载入完成后：
        load: function(event,ui){
            
            // 调整Bootstrap的按钮active颜色根据所需调整
            $('#tabs li').removeClass('active')
            ui.tab.addClass('active');
            
            // 每次clone都会append在其下面，删除 row>panel 的元素，
            $('#profile-row>div.ui-tabs-panel>div.profile-panel').remove();
            
            
            // 将载入的panel直接clone一个挂到所需要的位置
            $('#profile-row').append(ui.panel.clone());

        },        
    });
});
```

其中遇到了一个问题：

tab在原位置删除，并clone在新位置的过程中会现在原位置显示出来。
我想不闪那么一下，但是以下这些函数都没用

```js
load: function(event,ui){
    ui.panel.hide();
    // 最后再显示
    $('#profile-row').append(ui.panel.clone().show());
},
beforeActivate:function(event,ui){
    ui.newPanel.hide();
},
beforeLoad:function(event,ui){
    ui.panel.hide();
},
create: function(event,ui){
    ui.panel.hide();
}
```


同样也失败的思路：使用 $ui 提供的 Events 来移动 oldPanel 和 NewPanel(通过append移动)。
但是元素一旦移开该ui-tabs-panel不会再次生成。调用oldPanel只会报错。

最后我使用css解决。

**因此，使用这个方案同时还需要注意设置：**

```css
#tabs .profile-panel{
    display: none;
}
```


# Bootstrap 和 JQuery-ui 对于Tab实现的对比

- Bootstrap 的 显示方式更自由直观。只要规定好 `li a.data-toggle="tab".href="tab-div-id"` 和 `div.content#id` 即可。完全不用管这两部分之间的关系。在DOM树中距离多远都可以。

- JQuery-ui 的方式比较死板，必须互为兄弟节点。而且需要在js中执行 `$().tabs()` 
 
- JQuery-ui 我没有找到手动 click 一个 tab 的 API"

- JQuery-ui 的好处是提供了非常丰富的 Event 响应函数，在载入的每个阶段都提供断点进行操作

---
# 参考

- [jQuery tabs: how to create a link to a specific tab?](http://stackoverflow.com/questions/3601035/jquery-tabs-how-to-create-a-link-to-a-specific-tab)

- [WindowEventHandlers.onhashchange](https://developer.mozilla.org/en-US/docs/Web/API/WindowEventHandlers/onhashchange)

- [Bootstrap tab Usage](http://v3.bootcss.com/javascript/#tabs)

>You can activate individual tabs in several ways:
>```
>$('#myTabs a[href="#profile"]').tab('show') // Select tab by name
>$('#myTabs a:first').tab('show') // Select first tab
>$('#myTabs a:last').tab('show') // Select last tab
>$('#myTabs li:eq(2) a').tab('show') // Select third tab (0-indexed)
>```