<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\StationSupply;
use Illuminate\Http\Request;

class StationSupplyController extends Controller
{
    // Get the current supply levels
    public function index()
    {
        $supplies = StationSupply::orderBy('id')->get();

        return response()->json([
            'supplies' => $supplies,
        ], 200);
    }

    // Update the supply levels
    public function update(Request $request)
    {
        $validated = $request->validate([
            'foam_wash' => 'required|integer|min:0|max:100',
            'disinfectant' => 'required|integer|min:0|max:100',
            'water' => 'required|integer|min:0|max:100',
        ]);

        StationSupply::where('name', 'Foam Wash')
            ->update([
                'level' => $validated['foam_wash'],
            ]);

        StationSupply::where('name', 'Disinfectant')
            ->update([
                'level' => $validated['disinfectant'],
            ]);

        StationSupply::where('name', 'Water')
            ->update([
                'level' => $validated['water'],
            ]);

        return response()->json([
            'message' => 'Supply levels updated successfully.',
            'supplies' => StationSupply::orderBy('id')->get(),
        ], 200);
    }
}