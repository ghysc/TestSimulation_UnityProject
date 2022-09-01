using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FramerateManager : MonoBehaviour
{
    public int framerate = 30;

    private void Start() => Application.targetFrameRate = framerate;
}
