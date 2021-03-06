%include paper.fmt
%include LinearLogic.fmt

\hidden{
\begin{code}
open import Function using (case_of_; _∘_)
open import Data.List using (List; _++_; map) renaming (_∷_ to _,_; _∷ʳ_ to _,′_; [] to ∅)
open import Data.List.Properties using (map-++-commute)
open import Data.Product using () renaming (_×_ to _x'_)
open import Relation.Binary.PropositionalEquality as PropEq using (_≡_; refl; sym; cong)
\end{code}
}

\hidden{
\begin{code}
module LinearLogic (U : Set) (R : U) (⟦_⟧ᵁ : U → Set) where
\end{code}
}

\hidden{
\begin{code}
infixr 40 ¬_
infix  30 _⊗_
infixr 20 _⊸_
infix  4  _⊢_
\end{code}
}



\subsection{Moving down to linear logic}

As we have taken care to make all structural rules explicit, moving
down to intuitionistic linear logic (\textbf{LP}) from our current
model of \textbf{IL} is trivial. As a first step we define a new model
for our types, to match the conventions of linear logic (we are adding
bottom as an atomic type here, as we will need it later on).

\begin{code}
data Type : Set where
  el   : (A : U) → Type
  ⊥    : Type
  _⊗_  : Type → Type → Type
  _⊸_  : Type → Type → Type
\end{code}

\noindent
Next we can create the model of \textbf{LP} by copying our explicit
model for \textbf{IL}, and simply removing the axioms for weakening
and contraction.

%<*ill>
\begin{code}
data _⊢_ : ∀ (X : List Type) (A : Type) → Set where
  var   : ∀ {A} → A , ∅ ⊢ A
  abs   : ∀ {X A B} → A , X ⊢ B → X ⊢ A ⊸ B
  app   : ∀ {X Y A B} → X ⊢ A ⊸ B → Y ⊢ A → X ++ Y ⊢ B
  pair  : ∀ {X Y A B} → X ⊢ A → Y ⊢ B → X ++ Y ⊢ A ⊗ B
  case  : ∀ {X Y A B C } → X ⊢ A ⊗ B → A , B , Y ⊢ C → X ++ Y ⊢ C
  exch  : ∀ {X Y Z W A} →  (X ++ Z) ++ (Y ++ W) ⊢ A
        →  (X ++ Y) ++ (Z ++ W) ⊢ A
\end{code}
%</ill>

\noindent
And, since we added an atomic type for bottom, we can also add the
usual definition for negation.

\begin{code}
¬_ : Type → Type
¬ A = A ⊸ ⊥
\end{code}

\hidden{
\begin{code}
exch₀ : ∀ {A B C X} → A , B , X ⊢ C → B , A , X ⊢ C
exch₀ {A} {B} {X = X} t = exch {∅} {B , ∅} {A , ∅} {X} t
\end{code}
}

\noindent
Now we can define our running example. In fact, the definition has
hardly changed since \autoref{sec:IntuitionisticLogic}. The only
difference is that now the term \emph{has to be closed}, as swapping
in the presence of a context is not linear.

\begin{code}
swap : ∀ {A B} → ∅ ⊢ A ⊗ B ⊸ B ⊗ A
swap {A} {B} = abs (case var (exch₀ (pair var var)))
\end{code}

\noindent
As a new example, we can also give a proof for the validity of
type-raising.

\begin{code}
raise : ∀ {A B X} → X ⊢ A → X ⊢ (A ⊸ B) ⊸ B
raise t = abs (app var t)
\end{code}


%%% The following theorems are not in the paper, but required for the
%%% reification of Lambek-Grishin calculus into linear logic.

\hidden{
\begin{code}
++-assoc : ∀ {a} {A : Set a} (X Y Z : List A) → X ++ (Y ++ Z) ≡ (X ++ Y) ++ Z
++-assoc ∅ Y Z = refl
++-assoc (x , X) Y Z = cong (_,_ x) (++-assoc X Y Z)

xs++[]=xs : ∀ {a} {A : Set a} (xs : List A) → xs ++ ∅ ≡ xs
xs++[]=xs ∅ = refl
xs++[]=xs (x , xs) = cong (_,_ x) (xs++[]=xs xs)
\end{code}
}

\hidden{
\begin{code}
to-front : ∀ {X A B} → A , X ⊢ B → X ,′ A ⊢ B
to-front {X} {A} {B} t = lem1 lem2
  where
    lem1 : A , (X ++ ∅) ⊢ B → X ,′ A ⊢ B
    lem1 = exch {∅} {X} {A , ∅} {∅}
    lem2 : A , (X ++ ∅) ⊢ B
    lem2 rewrite xs++[]=xs X = t

to-back : ∀ {X A B} → X ,′ A ⊢ B → A , X ⊢ B
to-back {X} {A} {B} t = lem2
  where
    lem1 : A , X ++ ∅ ⊢ B
    lem1 = exch {∅} {A , ∅} {X} {∅} t
    lem2 : A , X ⊢ B
    lem2 rewrite sym (xs++[]=xs (A , X)) = lem1

YX↝XY : ∀ {A} X Y → Y ++ X ⊢ A → X ++ Y ⊢ A
YX↝XY {A} X Y t = lem₃
  where
    lem₁ : Y ++ X ++ ∅ ⊢ A
    lem₁ rewrite xs++[]=xs X = t
    lem₂ : X ++ Y ++ ∅ ⊢ A
    lem₂ = exch {∅} {X} {Y} {∅} lem₁
    lem₃ : X ++ Y ⊢ A
    lem₃ = PropEq.subst (λ Y → X ++ Y ⊢ A) (xs++[]=xs Y) lem₂

Y[XZ]↝X[YZ] : ∀ {A} X Y Z → Y ++ (X ++ Z) ⊢ A → X ++ (Y ++ Z) ⊢ A
Y[XZ]↝X[YZ] {A} X Y Z t = exch {∅} {X} {Y} {Z} t

[YX]Z↝[XY]Z : ∀ {A} X Y Z → (Y ++ X) ++ Z ⊢ A → (X ++ Y) ++ Z ⊢ A
[YX]Z↝[XY]Z {A} X Y Z t = lem₃
  where
    lem₁ : Y ++ (X ++ Z) ⊢ A
    lem₁ rewrite ++-assoc Y X Z = t
    lem₂ : X ++ (Y ++ Z) ⊢ A
    lem₂ = Y[XZ]↝X[YZ] X Y Z lem₁
    lem₃ : (X ++ Y) ++ Z ⊢ A
    lem₃ rewrite sym (++-assoc X Y Z) = lem₂

[XZ]Y↝[XY]Z : ∀ {A} X Y Z → (X ++ Z) ++ Y ⊢ A → (X ++ Y) ++ Z ⊢ A
[XZ]Y↝[XY]Z {A} X Y Z t = lem₃
  where
    lem₁ : (X ++ Z) ++ Y ++ ∅ ⊢ A
    lem₁ rewrite xs++[]=xs Y = t
    lem₂ : (X ++ Y) ++ Z ++ ∅ ⊢ A
    lem₂ = exch {X} {Y} {Z} {∅} lem₁
    lem₃ : (X ++ Y) ++ Z ⊢ A
    lem₃ = PropEq.subst (λ Z → (X ++ Y) ++ Z ⊢ A) (xs++[]=xs Z) lem₂

X[ZY]↝X[YZ] : ∀ {A} X Y Z → X ++ (Z ++ Y) ⊢ A → X ++ (Y ++ Z) ⊢ A
X[ZY]↝X[YZ] {A} X Y Z t = lem₃
  where
    lem₁ : (X ++ Z) ++ Y ⊢ A
    lem₁ rewrite sym (++-assoc X Z Y) = t
    lem₂ : (X ++ Y) ++ Z ⊢ A
    lem₂ = [XZ]Y↝[XY]Z X Y Z lem₁
    lem₃ : X ++ Y ++ Z ⊢ A
    lem₃ rewrite ++-assoc X Y Z = lem₂

XYZW↝XWZY : ∀ {A} X Y Z W → (X ++ Y) ++ (Z ++ W) ⊢ A → (X ++ W) ++ (Z ++ Y) ⊢ A
XYZW↝XWZY {A} X Y Z W t = lem₃
  where
    lem₁ : (X ++ Y) ++ (W ++ Z) ⊢ A
    lem₁ = X[ZY]↝X[YZ] (X ++ Y) W Z t
    lem₂ : (X ++ W) ++ (Y ++ Z) ⊢ A
    lem₂ = exch {X} {W} {Y} {Z} lem₁
    lem₃ : (X ++ W) ++ (Z ++ Y) ⊢ A
    lem₃ = X[ZY]↝X[YZ] (X ++ W) Z Y lem₂

XYZW↝YWXZ : ∀ {A} X Y Z W → (X ++ Y) ++ (Z ++ W) ⊢ A → (Y ++ W) ++ (X ++ Z) ⊢ A
XYZW↝YWXZ {A} X Y Z W t = lem₃
  where
    lem₁ : (Y ++ X) ++ (Z ++ W) ⊢ A
    lem₁ = [YX]Z↝[XY]Z Y X (Z ++ W) t
    lem₂ : (Y ++ X) ++ (W ++ Z) ⊢ A
    lem₂ = X[ZY]↝X[YZ] (Y ++ X) W Z lem₁
    lem₃ : (Y ++ W) ++ (X ++ Z) ⊢ A
    lem₃ = exch {Y} {W} {X} {Z} lem₂

XYZW↝ZXWY : ∀ {A} X Y Z W → (X ++ Y) ++ (Z ++ W) ⊢ A → (Z ++ X) ++ (W ++ Y) ⊢ A
XYZW↝ZXWY {A} X Y Z W t = lem₃
  where
    lem₁ : (X ++ Z) ++ (Y ++ W) ⊢ A
    lem₁ = exch {X} {Z} {Y} {W} t
    lem₂ : (Z ++ X) ++ (Y ++ W) ⊢ A
    lem₂ = [YX]Z↝[XY]Z Z X (Y ++ W) lem₁
    lem₃ : (Z ++ X) ++ (W ++ Y) ⊢ A
    lem₃ = X[ZY]↝X[YZ] (Z ++ X) W Y lem₂

XYZW↝ZYXW : ∀ {A} X Y Z W → (X ++ Y) ++ (Z ++ W) ⊢ A → (Z ++ Y) ++ (X ++ W) ⊢ A
XYZW↝ZYXW {A} X Y Z W t = lem₃
  where
    lem₁ : (Y ++ X) ++ (Z ++ W) ⊢ A
    lem₁ = [YX]Z↝[XY]Z Y X (Z ++ W) t
    lem₂ : (Y ++ Z) ++ (X ++ W) ⊢ A
    lem₂ = exch {Y} {Z} {X} {W} lem₁
    lem₃ : (Z ++ Y) ++ (X ++ W) ⊢ A
    lem₃ = [YX]Z↝[XY]Z Z Y (X ++ W) lem₂
\end{code}
}

\hidden{
\begin{code}
pair-left : ∀ {X A B C} → A , B , X ⊢ C → A ⊗ B , X ⊢ C
pair-left t = case var t

pair-left′ : ∀ {X A B C} → X ++ (A , B , ∅) ⊢ C → X ,′ A ⊗ B ⊢ C
pair-left′ {X} {A} {B} {C} = lem₃
  where
    lem₁ : X ,′ A ,′ B ⊢ C → X ,′ A ⊗ B ⊢ C
    lem₁ t = to-front (pair-left (to-back {B , X} {A} (to-back {X ,′ A} {B} t)))
    lem₂ : ∀ {a} {A : Set a} xs (y z : A) → xs ,′ y ,′ z  ≡ xs ++ (y , z , ∅)
    lem₂ ∅ y z = refl
    lem₂ (x , xs) y z = cong (_,_ x) (lem₂ xs y z)
    lem₃ : X ++ (A , B , ∅) ⊢ C → X ,′ A ⊗ B ⊢ C
    lem₃ rewrite sym (lem₂ X A B) = lem₁
\end{code}
}



\subsection{Reification into IL}
\label{sec:reifylp2il}

We could define the reification of \textbf{LP} into Agda as we showed
for \textbf{IL}, but it is much easier to translate our proofs to
\textbf{IL} and use the previously defined reification.

\hidden{
\begin{code}
open import IntuitionisticLogic U ⟦_⟧ᵁ as IL renaming (Type to TypeIL; _⊗_ to _×_)
open IL.Explicit
  hiding (swap; swap′)
  renaming (_⊢_ to _⊢IL_; ReifyType to ReifyTypeIL; ReifyCtxt to ReiftCtxtIL; [_] to reifyIL)
\end{code}
}

\hidden{
\begin{code}
instance
  ReifyType : Reify Type TypeIL
  ReifyType = record { ⟦_⟧ = ⟦_⟧ }
    where
\end{code}
}

We first define a translation of our types into the types of
\textbf{IL}. Note that we have abstracted over an element of the
user-provided type universe $U$---called $R$---to which we will map
bottom in the translation of our types.

\begin{code}
      ⟦_⟧ : Type → TypeIL
      ⟦ ⊥      ⟧ = el R
      ⟦ el A   ⟧ = el A
      ⟦ A ⊗ B  ⟧ = ⟦ A ⟧ × ⟦ B ⟧
      ⟦ A ⊸ B  ⟧ = ⟦ A ⟧ ⇒ ⟦ B ⟧
\end{code}

\hidden{
\begin{code}
open Reify {{...}} using (⟦_⟧)
\end{code}
}

\noindent
Next we define a translation function that maps contexts in
\textbf{LP} to contexts \textbf{IL}. Note that the implementation
simply applies the translation function to every element in the
context.

\hidden{
\begin{code}
instance
  ReifyCtxt : Reify (List Type) (List TypeIL)
  ReifyCtxt = record { ⟦_⟧ = map ⟦_⟧ }
\end{code}
}

\begin{spec}
⟦_⟧ : List Type → List TypeIL
⟦_⟧ = map ⟦_⟧
\end{spec}

\hidden{
\begin{code}
⟦X++Y⟧=⟦X⟧++⟦Y⟧ : (X Y : List Type) → ⟦ X ++ Y ⟧ ≡ ⟦ X ⟧ ++ ⟦ Y ⟧
⟦X++Y⟧=⟦X⟧++⟦Y⟧ X Y = map-++-commute ⟦_⟧ X Y
\end{code}
}

\noindent
Last, we define a translation from \textbf{LP} to \textbf{IL}. The
translation is almost able to reconstruct the proof in \textbf{IL}
verbatim, though we are omitting some minor details.\footnote{
  The problematic details have to do with the application of $⟦\_⟧$
  to contexts; we have to rewrite using a lemma that states that
  $⟦X \plus Y⟧ ≡ ⟦X⟧ \plus ⟦Y⟧$, i.e.\ that our translation commutes
  over context concatenation, for every binary rule.
}

\begin{spec}
toIL : X ⊢ A → ⟦ X ⟧ ⊢IL ⟦ A ⟧
toIL var         = var
toIL (abs t)     = abs (toIL t)
toIL (app s t)   = app (toIL s) (toIL t)
toIL (pair s t)  = pair (toIL s) (toIL t)
toIL (case s t)  = case (toIL s) (toIL t)
toIL (exch t)    = exch (toIL t)
\end{spec}

\hidden{
\begin{code}
toIL : ∀ {X A} → X ⊢ A → ⟦ X ⟧ ⊢IL ⟦ A ⟧
toIL var       = var
toIL (abs t)   = abs (toIL t)
toIL (app {X} {Y} s t)   rewrite ⟦X++Y⟧=⟦X⟧++⟦Y⟧ X Y  = app (toIL s) (toIL t)
toIL (pair {X} {Y} s t)  rewrite ⟦X++Y⟧=⟦X⟧++⟦Y⟧ X Y  = pair (toIL s) (toIL t)
toIL (case {X} {Y} s t)  rewrite ⟦X++Y⟧=⟦X⟧++⟦Y⟧ X Y  = case (toIL s) (toIL t)
toIL (exch {X} {Y} {Z} {W} {A} t)  = lem4
  where
    lem1 : ⟦ (X ++ Z) ++ (Y ++ W) ⟧ ⊢IL ⟦ A ⟧
    lem1 = toIL t
    lem2 : (⟦ X ⟧ ++ ⟦ Z ⟧) ++ (⟦ Y ⟧ ++ ⟦ W ⟧) ⊢IL ⟦ A ⟧
    lem2 rewrite  sym (⟦X++Y⟧=⟦X⟧++⟦Y⟧ X Z)
               |  sym (⟦X++Y⟧=⟦X⟧++⟦Y⟧ Y W)
               |  sym (⟦X++Y⟧=⟦X⟧++⟦Y⟧ (X ++ Z) (Y ++ W)) = lem1
    lem3 : (⟦ X ⟧ ++ ⟦ Y ⟧) ++ (⟦ Z ⟧ ++ ⟦ W ⟧) ⊢IL ⟦ A ⟧
    lem3 = exch {⟦ X ⟧} {⟦ Y ⟧} {⟦ Z ⟧} {⟦ W ⟧} lem2
    lem4 : ⟦ (X ++ Y) ++ (Z ++ W) ⟧ ⊢IL ⟦ A ⟧
    lem4 rewrite  ⟦X++Y⟧=⟦X⟧++⟦Y⟧ (X ++ Y) (Z ++ W)
               |  ⟦X++Y⟧=⟦X⟧++⟦Y⟧ X Y
               |  ⟦X++Y⟧=⟦X⟧++⟦Y⟧ Z W = lem3
\end{code}
}

\noindent
Then we can define the reification of closed terms into Agda by simple
function composition.

\begin{code}
[_] : {A : Type} {X : List Type} → X ⊢ A → (Ctxt ⟦ ⟦ X ⟧ ⟧ → ⟦ ⟦ A ⟧ ⟧)
[_] = reifyIL ∘ toIL
\end{code}


\noindent
And again, we can reify our (now linear) |swap| function back into Agda.

\begin{code}
swap′ : {A B : Type} → ⟦ ⟦ A ⟧ ⟧ x' ⟦ ⟦ B ⟧ ⟧ → ⟦ ⟦ B ⟧ ⟧ x' ⟦ ⟦ A ⟧ ⟧
swap′ {A} {B} = [ swap {A} {B} ] ∅
\end{code}
