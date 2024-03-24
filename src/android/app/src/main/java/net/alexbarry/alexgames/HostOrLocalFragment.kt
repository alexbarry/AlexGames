package net.alexbarry.alexgames

import android.app.AlertDialog
import android.os.Bundle
import androidx.fragment.app.Fragment
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import androidx.navigation.fragment.NavHostFragment

// TODO: Rename parameter arguments, choose names that match
// the fragment initialization parameters, e.g. ARG_ITEM_NUMBER
private const val ARG_PARAM1 = "param1"
private const val ARG_PARAM2 = "param2"

/**
 * A simple [Fragment] subclass.
 * Use the [HostOrLocalFragment.newInstance] factory method to
 * create an instance of this fragment.
 */
class HostOrLocalFragment : Fragment() {
    // TODO: Rename and change types of parameters
    private var param1: String? = null
    private var param2: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        arguments?.let {
            param1 = it.getString(ARG_PARAM1)
            param2 = it.getString(ARG_PARAM2)
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        // Inflate the layout for this fragment
        val view = inflater.inflate(R.layout.fragment_host_or_local, container, false)
        view.findViewById<Button>(R.id.btn_play_locally_offline).setOnClickListener {
            if (false) {
                val navHostFragment = NavHostFragment.findNavController(this)
                navHostFragment.navigate(R.id.action_hostOrLocalFragment_to_localClientWebView);
            }

            val alertDialog = AlertDialog.Builder(requireContext())
                .setTitle(R.string.local_client_popup_title)
                .setMessage(R.string.local_client_popup_message)
                .setPositiveButton(R.string.local_client_webview) { _, _ ->
                    val navHostFragment = NavHostFragment.findNavController(this)
                    navHostFragment.navigate(R.id.action_hostOrLocalFragment_to_localClientWebView);
                }
                .setNegativeButton(R.string.local_client_android) { _, _ ->
                    val navHostFragment = NavHostFragment.findNavController(this)
                    navHostFragment.navigate(R.id.action_hostOrLocalFragment_to_localClientAndroidGameSelector)
                }
                .create()
            alertDialog.show()
        }

        view.findViewById<Button>(R.id.btn_host_server).setOnClickListener {
            val navHostFragment = NavHostFragment.findNavController(this)
            navHostFragment.navigate(R.id.action_hostOrLocalFragment_to_serverCreationFragment)
        }
        return view
    }

    companion object {
        /**
         * Use this factory method to create a new instance of
         * this fragment using the provided parameters.
         *
         * @param param1 Parameter 1.
         * @param param2 Parameter 2.
         * @return A new instance of fragment HostOrLocalFragment.
         */
        // TODO: Rename and change types and number of parameters
        @JvmStatic
        fun newInstance(param1: String, param2: String) =
            HostOrLocalFragment().apply {
                arguments = Bundle().apply {
                    putString(ARG_PARAM1, param1)
                    putString(ARG_PARAM2, param2)
                }
            }
    }
}