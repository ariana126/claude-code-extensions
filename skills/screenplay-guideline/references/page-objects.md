# Page Objects Under Screenplay

Read this when building widget abstractions, deciding what a Page Object is
allowed to do, or locating elements in a DOM with no test-friendly identifiers.

## Contents

- [Three variants compared](#three-variants-compared)
- [Lean Page Object](#lean-page-object)
- [Companion Page Object](#companion-page-object)
- [Element location and composition](#element-location-and-composition)
- [Page Element Query Language](#page-element-query-language)
- [Sharing test code across teams](#sharing-test-code-across-teams)

## Three variants compared

| | Classic Page Object | **Lean Page Object** | **Companion Page Object** |
|---|---|---|---|
| Responsibilities | Locate elements **and** model interactions | **Only** provide information about the widget | Provide element access **and** tasks, host element injected |
| Why | The pre-Screenplay default | Screenplay's tasks and interactions already model behavior | Ship test code alongside a widget library |
| Returns | Values | `PageElement` / `QuestionAdapter` | **Tasks** and question adapters, so results compose into higher-level types |

Under Screenplay, prefer **Lean**. Reach for **Companion** only when publishing
test code for consumers outside your team.

Two rules hold for all variants: never assert inside a Page Object, and never
expose the raw driver or a tool-specific element type.

Model *components*, not whole pages. Page Object hierarchies that mirror the
application's page structure accumulate unrelated fields grouped together merely
because they share a screen.

## Lean Page Object

Its job is to translate low-level markup into domain concepts, and stop there:

```typescript
import { By, CssClasses, PageElement } from '@serenity-js/web'
import { QuestionAdapter } from '@serenity-js/core'

export class Toaster {
    private static component = () =>
        PageElement.located(By.css(`.ngx-toastr`)).describedAs('toaster')

    static message = () =>
        PageElement.located(By.css(`.toast-message`))
            .of(Toaster.component())
            .describedAs('message')

    static status = () =>
        CssClasses.of(Toaster.component())
            .filter(cssClass => cssClass.startsWith('toast-'))
            .map(cssClass => cssClass.replace('toast-', ''))
            .slice(0, 1)[0]
            .describedAs('toaster status') as QuestionAdapter<string>
}
```

Note what `status()` achieves: the CSS classes `toast-success` and `toast-error`
become the values `'success'` and `'error'`. A low-level implementation detail
has become a meaningful state of the widget, which assertions can read directly.

The behavior lives in a task, not the Page Object:

```typescript
export class VerifySubmission {
  static succeededWith(expectedMessage: string) {
    return Task.where(`#actor confirms successful form submission`,
      VerifySubmission.hasMessage(expectedMessage),
      VerifySubmission.hasStatus('success'),
      VerifySubmission.dismissMessage(),
    )
  }

  static failedWith(expectedMessage: string) {
    return Task.where(`#actor confirms failed form submission`,
      VerifySubmission.hasMessage(expectedMessage),
      VerifySubmission.hasStatus('error'),          // the only difference
      VerifySubmission.dismissMessage(),
    )
  }

  private static hasMessage(message: string) {
    return Task.where(`#actor confirms notification includes ${ message }`,
      Wait.until(Toaster.message(), isPresent()),
      Ensure.that(Text.of(Toaster.message()), includes(message)),
    )
  }

  private static hasStatus(status: 'success' | 'error') {
    return Task.where(`#actor confirms form submission ${ status }`,
      Wait.until(Toaster.message(), isPresent()),
      Ensure.that(Toaster.status(), equals(status)),
    )
  }

  private static dismissMessage() {
    return Task.where(`#actor dismisses the message`,
      Wait.until(Toaster.message(), isPresent()),
      Click.on(Toaster.message()),
      Wait.until(Toaster.message(), not(isPresent())),
    )
  }
}
```

A toast is transient and animated, so verifying one genuinely needs four steps:
wait for it to appear, check the text, dismiss it, and wait for it to go. Naming
that sequence is what keeps the step definition readable.

## Companion Page Object

Same widget, but the host element is injected and the methods return tasks:

```typescript
export class Toaster {
  constructor(private readonly hostElement: QuestionAdapter<PageElement>) {}

  message = () =>
    PageElement.located(By.css(`.toast-message`))
      .of(this.hostElement).describedAs('message')

  status = () =>
    CssClasses.of(this.hostElement)
      .filter(cssClass => cssClass.startsWith('toast-'))
      .map(cssClass => cssClass.replace('toast-', ''))
      .slice(0, 1)[0]
      .describedAs('toaster status') as QuestionAdapter<string>

  dismissMessage = () =>                       // returns a Task, not void
    Task.where(`#actor dismisses the message`,
      Wait.until(this.message(), isPresent()),
      Click.on(this.message()),
      Wait.until(this.message(), not(isPresent())),
    )
}
```

Injecting the host means the same widget abstraction works wherever the component
appears, including containers only known at runtime.

## Element location and composition

Three ways to locate an element, in increasing order of flexibility:

```typescript
// Absolute, relative to the browsing context
const ToasterMessage = () =>
    PageElement.located(By.css(`.ngx-toastr > .toast-message`))
        .describedAs('toaster message')

// Relative to a containing element
const Toaster = () =>
    PageElement.located(By.css(`.ngx-toastr`)).describedAs(`toaster`)

const ToasterMessage = () =>
    PageElement.located(By.css(`.toast-message`))
        .of(Toaster())
        .describedAs('message')

// Chained with a runtime-injected host
const NotificationsSection = () =>
    PageElement.located(By.id(`notifications`)).describedAs(`notifications section`)

const SpecificMessage = ToasterMessage().of(NotificationsSection())
```

Always call `.describedAs(...)` — the description is what appears in reports, and
it is the difference between a readable failure and a CSS selector.

## Page Element Query Language

Some component libraries give you nothing to select on. Angular Material renders
a form field as several nested divs with no stable identifier tying the input to
its label:

```html
<mat-form-field>
    <div class="mat-form-field-wrapper">
        <div class="mat-form-field-flex">
            <div class="mat-form-field-infix">
                <input name="email">
                <span><label for="email" aria-owns="email">
                    <mat-label>Email</mat-label>
                </label></span>
            </div>
        </div>
        <div><mat-error>Please enter your email</mat-error></div>
    </div>
</mat-form-field>
```

Query by what a *user* sees — the label text — rather than by brittle structure:

```typescript
import { matches, includes, isPresent } from '@serenity-js/assertions'
import { By, PageElement, PageElements, Text } from '@serenity-js/web'

export class Form {
    static buttonCalled = (name: string) =>
        Form.buttons().where(Text, includes(name)).first()
            .describedAs(`the "${ name }" button`)

    static inputFor = (name: string) =>
        Form.input().of(Form.fieldCalled(name))
            .describedAs(`the "${ name }" field`)

    static errorMessageFor = (name: string) =>
        Text.of(Form.errorMessage().of(Form.fieldCalled(name))
                   .describedAs(`the error message for "${ name }" field`))

    private static fieldCalled = (name: string) =>
        Form.fields()
            .where(Form.label(), isPresent())
            .where(Text.of(Form.label()), matches(new RegExp(name, 'i')))
            .first()

    public static buttons = () =>
        PageElements.located(By.css('button')).describedAs('buttons')

    public static fields = () =>
        PageElements.located(By.css('mat-form-field')).describedAs('form fields')

    public static label = () =>
        PageElement.located(By.css('label > mat-label, label > span')).describedAs('label')

    private static input = () => PageElement.located(By.css('input'))
    private static errorMessage = () => PageElement.located(By.css('mat-error'))
}
```

Which collapses a task down to one line:

```typescript
export const SpecifyEmailAddress = (emailAddress: Answerable<string>) =>
    Task.where(`#actor specifies their email address`,
        Enter.theValue(emailAddress).into(Form.inputFor('Email')))
```

The query language uses the **same expectations** as `Ensure.that` and
`Wait.until`, and accepts your own custom questions and expectations.

## Sharing test code across teams

A component team automates its widget tests to a high standard, and consumer
teams get none of that benefit. They rediscover the same selectors, must keep
their higher-level tests in sync with the component team's changes, and can be
broken silently when HTML structure shifts underneath them.

The fix is for component teams to **publish** their Screenplay test code,
versioned alongside the component. Ship it in the same Node module as the widgets
but under a **separate entry point**, so shared test code never interferes with
production code.
