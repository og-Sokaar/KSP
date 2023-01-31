// Fixed Launch

function main {
    doLaunch().
    doAscent().
    until apoapsis > 80000 {
        doAutoStage().
    }
    doShutdown().
    //wait until altitude >= 65000.
    //stage.
    // stage.
    // doCoast().
    doCircularisation().
    doShutdown().
    if periapsis > 71000 {
        Print "Congratulations, Stable Orbit Achieved!".
        wait 10.
    // Decent().
        clearScreen.
    } else {
        print "Orbit Failed!.".
    }
    print "goodbye!".
    shutdown.
}

function doShutdown {
    lock throttle to 0.
    lock steering to prograde.
    //if periapsis > 71000 {
    //    Print "Congratulations, Stable Orbit Achieved!".
    //    wait 10.
        //Decent().
    //    clearScreen.
    //} else {
    //    print "Orbit Failed!.".
    //}
    //print "goodbye!".
    //shutdown.

}

function doCoast {
    print "Coasting to appropriate altitude...".
    until eta:apoapsis <= 30 {
        lock throttle to 0.
    }
}

function doCircularisation {
    print "Calculating orbit eccentricity...".
    local circ is list(0).
    set circ to improveConverge(circ, eccentricityScore@).
    wait until altitude > 70000.
    print "Done!".
    executeManeuver(list(time:seconds + eta:apoapsis, 0, 0, circ[0])).
}

function eccentricityScore {
  parameter data.
  local mnv is node(time:seconds + eta:apoapsis, 0, 0, data[0]).
  addManeuverToFlightPlan(mnv).
  local result is mnv:orbit:eccentricity.
  removeManeuverFromFlightPlan(mnv).
  return result.
}

function improveConverge {
  parameter data, scoreFunction.
  for stepSize in list(100, 10, 1) {
    until false {
      local oldScore is scoreFunction(data).
      set data to improve(data, stepSize, scoreFunction).
      if oldScore <= scoreFunction(data) {
        break.
      }
    }
  }
  return data.
}

function improve {
  parameter data, stepSize, scoreFunction.
  local scoreToBeat is scoreFunction(data).
  local bestCandidate is data.
  local candidates is list().
  local index is 0.
  until index >= data:length {
    local incCandidate is data:copy().
    local decCandidate is data:copy().
    set incCandidate[index] to incCandidate[index] + stepSize.
    set decCandidate[index] to decCandidate[index] - stepSize.
    candidates:add(incCandidate).
    candidates:add(decCandidate).
    set index to index + 1.
  }
  for candidate in candidates {
    local candidateScore is scoreFunction(candidate).
    if candidateScore < scoreToBeat {
      set scoreToBeat to candidateScore.
      set bestCandidate to candidate.
    }
  }
  return bestCandidate.
}

function executeManeuver {
  parameter mList.
  local mnv is node(mList[0], mList[1], mList[2], mList[3]).
  addManeuverToFlightPlan(mnv).
  local startTime is calculateStartTime(mnv).
  warpto(startTime - 15).
  wait until time:seconds > startTime - 10.
  lockSteeringAtManeuverTarget(mnv).
  wait until time:seconds > startTime.
  lock throttle to 1.
  until isManeuverComplete(mnv) {
    doAutoStage().
  }
  lock throttle to 0.
  unlock steering.
  removeManeuverFromFlightPlan(mnv).
}

function addManeuverToFlightPlan {
    parameter mnv.
    add mnv.
}

function calculateStartTime {
    parameter mnv.
    return time:seconds + mnv:eta - maneuverBurnTime(mnv) / 2.
}

function maneuverBurnTime {
    parameter mnv.
    local dV is mnv:deltaV:mag.
    local g0 is 9.80665.
    local isp is 0.

    list engines in myEngines.
    for en in myEngines {
        if en:ignition and not en:flameout{
            set isp to isp + (en:isp * (en:availableThrust / ship:availablethrust)).
        }
    }

    local mf is ship:mass / constant():e^(dV / (isp * g0)).
    local fuelFlow is ship:availablethrust / (isp * g0).    
    local t is (ship:mass - mf) / fuelFlow.

    return t.    
}

function lockSteeringAtManeuverTarget {
    parameter mnv.
    lock steering to mnv:burnvector.
}

function isManeuverComplete {
    parameter mnv.
        if not(defined originalVector) or originalVector = -1 {
        global originalVector is mnv:burnvector.
    }
    if vAng(originalVector, mnv:burnvector) > 90 {
        declare global originalVector to -1.
        return true.
    }
    return false.
}

function removeManeuverFromFlightPlan {
    parameter mnv.
    remove mnv.
}

function doSafeStage {
    wait until stage:ready.
    print "Staging...".
    stage.
}

function doLaunch {
    lock throttle to 1.
    doSafeStage().
    doSafeStage().
}

function doAscent {
    lock targetPitch to 88.963 - 1.03287 * alt:radar^0.409511.
    set targetDirection to 96.
    lock steering to heading(targetDirection, targetPitch).
}

function doAutoStage { 
    if not(defined oldThrust) {
        global oldThrust is ship:availablethrust.
    }
    if ship:availableThrust < (oldThrust - 10) {
        doSafeStage(). wait 1.
        global oldThrust is ship:availablethrust.
    }
}

function doDecentBurn {
    sas off.
    print "Starting Decent..".
    wait 3.
    lock steering to ship:srfretrograde.
    wait 5.
    lock throttle to 1.
}

function Decent {
    doDecentBurn().
        until periapsis < 35000. {
        lock throttle to 0.
        wait 10.
        }
    lock steering to ship:srfRetrograde.
    wait until ship:altitude <= 65000.
    print "Staging...".
    stage.
    wait until ship:altitude <= 5000.
    print "Deploying chute(s)!".
    stage.
//    doFinalStage().
//    doParachute().
}

main().