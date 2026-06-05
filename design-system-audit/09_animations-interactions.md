# 🎬 Animations & Interactions Audit

## Core Interaction Patterns
- **Hover**: Subtle background change to `bgHover` (#F3F4F6). 150ms-200ms transition.
- **Click Feedback**: Ripple effect (standard Material) or opacity shift for iOS-style buttons.
- **Transitions**:
  - **Master-Detail**: Slide-in or Fade-in for the detail pane.
  - **Modals**: Scale-up with fade (standard Material/GoRouter transition).
  - **Sidebar**: Horizontal slide/collapse (250ms).

## Loading States
- **Skeletons**: Used extensively for initial data loads.
- **Toasts**: Slide-in from the top-center or bottom-center. Stays for 3-5 seconds.
- **Progress Bars**: Used for long-running sync operations.

## Microinteractions
- **Tooltip**: Appear on hover with 500ms delay.
- **Button Loading**: Label replaced with a small spinner or "Saving..." state.
- **Success Checkmarks**: Animated checkmarks in confirmation dialogs.

## Libraries
- **Flutter Animations**: `AnimationController`, `Tween`.
- **Navigation**: `GoRouter` for page transitions.

## Inconsistencies
- **Transition Speed**: Some modals pop in instantly while others have a slow fade. Recommended to standardize on 200ms duration.
- **Feedback**: Lack of ripple effect on some custom `InkWell` implementations.

## Recommended Standard
Use `AnimatedContainer` or `AnimatedSwitcher` for simple state transitions. All primary buttons must show a loading spinner when `onPressed` triggers an async operation.
