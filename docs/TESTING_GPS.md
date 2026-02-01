# Testing GPS distance at your desk (Simulator)

WalkyTrails uses **CoreLocation** to measure walk distance. You can test it without moving by using the **iOS Simulator’s simulated location**.

---

## 1. Simulate movement in the Simulator

1. **Run the app** on the **iPhone Simulator** (e.g. iPhone 16 Pro) from Xcode (⌘R).
2. In the **Simulator menu bar**: **Features → Location** (or **Debug → Simulate Location** in Xcode).
3. Choose one of:
   - **City Run** – simulates a running route; location updates over time (good for walks).
   - **Freeway Drive** – simulates driving; faster movement.
   - **City Bicycle Ride** – slower than drive.
4. In the app: tap **Start Walk**.
5. Allow location when prompted (**Allow While Using App**).
6. Leave the simulator running. As the simulated location moves, **distance** in the app will increase (e.g. "0.12 km", "0.25 km").
7. Tap **End Walk** → **Save**. Open **History** and tap the walk to see **distance** in the detail view.

---

## 2. Custom route (GPX file, optional)

To test a specific path:

1. Create a **.gpx** file with waypoints (e.g. a short loop). You can use [gpx.studio](https://gpx.studio) or add a file to the project.
2. In Xcode: **Debug → Simulate Location → Add GPX File to Project…** (or choose an existing one).
3. Run the app, start a walk, then **Debug → Simulate Location → [Your GPX file]**.
4. The simulator will “walk” the route; distance will accumulate.

---

## 3. Single fixed location (sanity check)

- **Features → Location → Custom Location…** and enter lat/long.
- Use this to confirm the app doesn’t crash and permission works. Distance will stay 0 because the location doesn’t move.

---

## 4. On a real device

- Take your iPhone outside (or walk around); start a walk and move. Distance will update from GPS.
