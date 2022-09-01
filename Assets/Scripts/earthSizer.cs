using System.Collections;
using System.Collections.Generic;
using UnityEngine;


[ExecuteInEditMode]
public class earthSizer : MonoBehaviour
{
    [Range(1.0f, 63.71f)]
    public float radius = 6.3741f;
    private float _radius = 0.0f;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        if(_radius != radius)
        {
            _radius = radius;
            transform.localScale = new Vector3(_radius * 2, _radius * 2, _radius * 2);
        }
    }
}
