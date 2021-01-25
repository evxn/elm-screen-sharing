# Css Task

Solutions for all 3 requests can be found in the corresponding folders.

You can try it with:
```sh
open request1/index.html
```

 Here's a quick summary.

### Request 1

> Replace the logo The customer wants to replace the logo with a nice big image on the left side of the form fields. What options do you see, and which option would you prefer and why?

Css grid is a power tool for styling a flat hierarchy. Since we support the latest browsers, I’d switch from flexbox to the grid version.

As for replacing the image, it’s a bit gloomier choice.
`content: url(https://…)` is a nice solution, but it won't work in Firefox. So I used an old trick with replacing image with padding covered by a background url. The main downside is that image size have to be hardcoded. And we also loose smooth responsive scaling, but it’s supported everywhere.
`img::before` and `img::after` pseudo-elements have their rendering quirks between the browsers and it didn't work for me.

```css
form.login > img {
  width: 0;
  height: 0;
  padding-top: calc(4 * (18px + 42px + 1em) + 3em);
  padding-left: 100%;
  background: url("https://d.ibtimes.co.uk/en/full/1493575/big-bang.jpg") no-repeat;
}
```

### Request 2

> Swap field order One customer wants to swap the order of session number and user name

Flex box order is to the rescue: 

```css
form.login :nth-child(n+2) {
  order: 4;
}
form.login [for="session"],
form.login #session { 
  order: 3;
}
form.login [for="account"],
form.login #account {
  order: 2;
}
form.login [for="username"],
form.login #username {
  order: 1;
}
```

### Request 3

> Hide the account field from the user Each employee of the customer needs to enter the same data into the account field. The customer wants us to hide this field and use one value for all its employees. Do you see options how this can be achieved with minimal changes to the other brands?

Since all the fields may be pre-filled with url parameters, we can do just that for that brand and pre-fill the account value. The corresponding field and label can be hidden with simple

```css
form.login [for="account"],
form.login #account {
  display: none;
}
```

