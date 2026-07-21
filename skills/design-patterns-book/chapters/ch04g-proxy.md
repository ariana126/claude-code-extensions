# Proxy
**Classification**: Object Structural | **Chapter**: 4

## Intent
Provide a surrogate or placeholder for another object to control access to it.

## Also Known As
Surrogate

## Core Idea
Put a stand-in with the *identical* interface in front of the real subject, so
clients can't tell the difference — and use that indirection to defer creation,
cross an address space, check permissions, or do housekeeping.

## Applicability
Use Proxy whenever you need a more versatile or sophisticated reference to an
object than a plain pointer. The four kinds:

1. **Remote proxy** — a local representative for an object in a different address space. NeXTSTEP's `NXProxy`; Coplien calls this an "Ambassador." It encodes the request and its arguments and ships them to the real subject; the subject encodes results back.
2. **Virtual proxy** — creates expensive objects on demand. The `ImageProxy` of the Motivation: opening a document must be fast, and not every image is visible, so the real `Image` is instantiated only when `Draw` is called. It caches the extent so the formatter can ask for size without triggering creation.
3. **Protection proxy** — controls access to the original object when different clients should have different access rights. The Choices OS's `KernelProxies` provide protected access to operating system objects.
4. **Smart reference** — a replacement for a bare pointer that performs extra actions on access: counting references so the object frees itself when the count hits zero (*smart pointers*); loading a persistent object into memory on first reference; verifying the real object is locked before access.

## Structure
- **Subject** (Graphic): the common interface for RealSubject and Proxy, so a Proxy can be substituted wherever a RealSubject is expected.
- **RealSubject** (Image): the real object the proxy represents.
- **Proxy** (ImageProxy): maintains a reference letting it access the real subject (it may refer to a *Subject* if the RealSubject and Subject interfaces are identical); provides an interface identical to Subject's; controls access to the real subject and may create and delete it. Remaining responsibilities depend on the kind — remote proxies encode and transmit requests; virtual proxies cache information (the image extent) so they can postpone access; protection proxies check the caller's permissions.

Collaboration: Proxy forwards requests to RealSubject when appropriate, depending on the kind of proxy.

## How
1. Define the Subject interface (or reuse the RealSubject's if you control it) so Proxy and RealSubject are interchangeable.
2. Give Proxy a reference to the subject. Before it exists, refer to it with an address-space-independent identifier: a file name, a "host ID plus local address."
3. Implement each Subject operation on the Proxy: verify the request is legal, ensure the real object exists, then forward — or answer from cached state where that's cheaper.
4. Cache whatever lets you postpone instantiation (extent, size, metadata).
5. Because these forwarding operations are near-identical and tedious, it's common to generate them with a preprocessor.

## Consequences
**Benefits**
- Introduces a level of indirection with many uses: a **remote proxy hides that an object lives in a different address space**; a **virtual proxy enables optimizations like creation on demand**; **protection proxies and smart references allow housekeeping** whenever an object is accessed.
- **Copy-on-write.** Copying a large object is expensive and pointless if the copy is never modified. Copying the proxy only increments the subject's reference count; the proxy copies the subject only when the client requests a modifying operation, decrementing the original's count (the subject is deleted at zero). This can reduce the cost of copying heavyweight subjects significantly.

**Liabilities**
- Extra indirection on every access, plus an object per reference.
- Writing the forwarding operations is repetitive and error-prone.
- With Smalltalk's `doesNotUnderstand:` approach, identity semantics break and dispatch is slow.
- A protection proxy may refuse operations the subject would perform, so its interface is effectively a *subset* of the subject's.

## Implementation Notes
- **Overloading `operator->` in C++.** Overloading the member access operator lets you do work whenever the object is dereferenced — an `ImagePtr` that calls `LoadImage` from `operator->` and `operator*` behaves like a pointer and lets you call `Image` operations without replicating them in the proxy's interface. Two catches: `ImagePtr` isn't declared as a pointer to `Image`, so clients must still treat the two differently; and some proxies must know *precisely which* operation was called. The Motivation's virtual proxy is exactly that case — the image must load on `Draw`, not on every reference — so you must hand-implement each forwarding operation.
- **Using `doesNotUnderstand:` in Smalltalk.** Smalltalk calls `doesNotUnderstand: aMessage` when a receiver has no matching method; redefine it to forward to the subject via `perform:withArguments:`. To ensure nothing is silently absorbed, define Proxy as a class **with no superclass** (so it understands *nothing*). NeXTSTEP's `NXProxy` uses the equivalent hook, `forward`. Disadvantages: a few special messages are handled directly by the VM and bypass method lookup — notably identity `==`, so **identity on proxies cannot mean identity on subjects**; and `doesNotUnderstand:` was built for error handling, so it's generally slow. It does allow arbitrary processing: check the message against a `legalMessages` set to build a protection proxy (and copy `error:` from Object, or you get an infinite error loop).
- **Proxy needn't know the real subject's type.** If a Proxy deals with its subject through an abstract interface only, one Proxy class serves all RealSubject classes uniformly — you don't need a proxy per subject. But a proxy that *instantiates* the real subject (a virtual proxy) must know the concrete class.

## Worked Example
A document editor embeds images; large rasters are expensive to create but the
document must open fast.

```cpp
class ImageProxy : public Graphic {
public:
    ImageProxy(const char* fileName) {
        _fileName = strdup(fileName);
        _extent   = Point::Zero;      // don't know it yet
        _image    = 0;
    }
    virtual const Point& GetExtent() {
        if (_extent == Point::Zero) { _extent = GetImage()->GetExtent(); }
        return _extent;               // cached — answer without loading
    }
    virtual void Draw(const Point& at) { GetImage()->Draw(at); }
    virtual void HandleMouse(Event& e) { GetImage()->HandleMouse(e); }
    virtual void Save(ostream& to)     { to << _extent << _fileName; }
protected:
    Image* GetImage() {
        if (_image == 0) { _image = LoadImage(_fileName); }
        return _image;
    }
private:
    Image* _image;
    Point  _extent;
    char*  _fileName;
};

TextDocument* text = new TextDocument;
text->Insert(new ImageProxy("anImageFileName"));   // no image loaded yet
```

What it demonstrates: the formatter can lay out the document by calling
`GetExtent` without ever instantiating the image; the real `Image` appears only
when someone draws it. The file name doubles as an address-space-independent
identifier for a subject that isn't in memory yet.

## Anti-patterns & Smells
- **Changing the interface in the proxy**: that makes it an Adapter. A proxy's interface is identical to its subject's.
- **Relying on identity through a proxy**: `proxy == realSubject` is false, and in Smalltalk `==` bypasses `doesNotUnderstand:` entirely.
- **Using `operator->` when the trigger point matters**: dereference-time loading can't express "load on `Draw`, not on every reference."
- **Hand-writing dozens of identical forwarding methods**: generate them, or use a language hook.
- **Building a proxy per RealSubject class needlessly**: if the proxy only needs the abstract interface, one class covers them all.

## Known Uses
- **ET++** text building block classes — the virtual image proxy of the Motivation.
- **NeXTSTEP** — `NXProxy` as a local representative for distributed objects; the server creates proxies on client request, and the proxy encodes messages and arguments for transmission to the remote subject.
- **Choices operating system** — `KernelProxies` for protected access to OS objects.
- **McCullough** — proxies in Smalltalk for accessing remote objects; **Pascoe's "Encapsulators"** — side effects on method calls plus access control.
- **Iterator** — the book notes another kind of proxy in the Iterator pattern.

## Related Patterns
- **Adapter**: an adapter provides a **different** interface to the object it adapts; a proxy provides the **same** interface as its subject. (A protection proxy that refuses some operations effectively exposes a *subset* of that interface.)
- **Decorator**: implementations can look nearly identical — both compose an object, present an identical interface, and forward requests — but the purposes differ. A **decorator adds responsibilities**; a **proxy controls access**. In Proxy the subject defines the key functionality and the proxy grants or refuses access to it; in Decorator the component provides only part of the functionality and one or more decorators supply the rest. That open-endedness makes **recursive composition essential to Decorator and irrelevant to Proxy**, which focuses on a single, statically expressible proxy-subject relationship. Proxies vary in how decorator-like they are: a protection proxy might be implemented exactly like a decorator; a remote proxy holds only an *indirect* reference (host ID plus local address); a virtual proxy starts indirect (a file name) and later obtains a direct one. Hybrids (a proxy-decorator, a decorator-proxy for a remote object) are conceivable but decompose into the two patterns.
- **Composite**: the third pattern built on recursive composition. Composite's intent is **aggregation and uniform representation**, Decorator's is **added responsibility**, Proxy's is **controlled access** — same mechanism, three different problems.
- **Flyweight**: also multiplies indirection to a shared object, but for space efficiency via the intrinsic/extrinsic split rather than access control.
- **Iterator**: describes another kind of proxy.

## Key Takeaways
1. Name the kind of proxy you're building — remote, virtual, protection, or smart reference — because it determines what the proxy caches, when it forwards, and whether it must know the subject's concrete class.
2. Keep the interface identical to the subject's; the moment you change it you've written an Adapter, and clients lose substitutability.
3. Cache exactly the state that lets you postpone contacting the subject (the image's extent) — that's what makes a virtual proxy pay off.
4. Never rely on object identity across a proxy boundary, in any language.
5. Proxy, Decorator, and Composite share a structure and nothing else: access control vs. added responsibility vs. aggregation.
